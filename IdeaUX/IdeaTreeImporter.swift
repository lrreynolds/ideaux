import Foundation
import SwiftData

struct IdeaMarkdownNormalizer {
    static func normalize(_ markdown: String) -> String {
        var lines = markdown.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        // Strip common markdown code fences.
        lines = lines.filter { line in
            let lower = line.lowercased()
            return lower != "```" && lower != "```markdown" && lower != "```md"
        }

        // Drop leading commentary before a likely collection title.
        while let first = lines.first, first.isEmpty {
            lines.removeFirst()
        }

        // If no "# " title exists, treat first non-empty plain line as collection title.
        if let firstNonEmptyIndex = lines.firstIndex(where: { !$0.isEmpty }) {
            let first = lines[firstNonEmptyIndex]
            if !first.hasPrefix("#") && !first.lowercased().hasPrefix("purpose:") {
                lines[firstNonEmptyIndex] = "# \(first)"
            }
        }

        // If a "# " heading exists later, drop anything before it.
        if let firstHeadingIndex = lines.firstIndex(where: { $0.hasPrefix("# ") }) {
            lines = Array(lines[firstHeadingIndex...])
        }

        // Normalize bullets.
        lines = lines.map { line in
            if line.hasPrefix("* ") { return "- " + line.dropFirst(2) }
            if line.hasPrefix("+ ") { return "- " + line.dropFirst(2) }
            if line.hasPrefix("• ") { return "- " + line.dropFirst(2) }
            return line
        }

        // Convert bare section titles followed by bullets into ## headings.
        var normalized: [String] = []

        for index in lines.indices {
            let line = lines[index]
            let previous = index > lines.startIndex ? lines[lines.index(before: index)] : ""
            let next = index < lines.index(before: lines.endIndex) ? lines[lines.index(after: index)] : ""

            let isHeading = line.hasPrefix("#")
            let isBullet = line.hasPrefix("- ")
            let isMetadata = line.lowercased().hasPrefix("purpose:")
                || line.lowercased().hasPrefix("goals:")
                || line.lowercased().hasPrefix("key concepts:")
                || line.lowercased().hasPrefix("background context:")
                || line.lowercased().hasPrefix("refinement instructions:")

            let looksLikeBareSection =
                !line.isEmpty &&
                !isHeading &&
                !isBullet &&
                !isMetadata &&
                previous.isEmpty &&
                next.hasPrefix("- ")

            if looksLikeBareSection {
                normalized.append("## \(line)")
            } else {
                normalized.append(line)
            }
        }

        // Remove empty leading/trailing lines.
        while normalized.first?.isEmpty == true {
            normalized.removeFirst()
        }
        while normalized.last?.isEmpty == true {
            normalized.removeLast()
        }

        return normalized.joined(separator: "\n")
    }
}

struct IdeaImportDebug {
    static var enabled = true

    static func log(_ title: String, _ text: String) {
#if DEBUG
        guard enabled else { return }

        print("\n====================")
        print("IDEA IMPORT DEBUG")
        print(title)
        print("====================")
        print(text)
        print("====================\n")
#endif
    }
}

struct IdeaTreeImporter {
    enum ImportMode {
        case createNewCopy
        case replaceExisting
    }
    static func importMarkdown(_ markdown: String, into collection: IdeaCollection, context: ModelContext) {
        let normalizedMarkdown = IdeaMarkdownNormalizer.normalize(markdown)
        let lines = normalizedMarkdown.components(separatedBy: .newlines)
        
        IdeaImportDebug.log("RAW MARKDOWN", markdown)
        IdeaImportDebug.log("NORMALIZED MARKDOWN", normalizedMarkdown)
        
        // Track the last created nodes for hierarchy inference
        var lastRoot: IdeaNode? = nil
        var lastHeading: IdeaNode? = nil // latest heading (## or ###)
        
        func clean(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        func inferType(from title: String) -> String {
            let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = t.lowercased()
            if t.hasSuffix("?") || lower.contains("question") { return "question" }
            if lower.contains("decision") { return "decision" }
            if lower.contains("implemented") { return "implementation" }
            if lower.hasPrefix("build ") || lower.hasPrefix("add ") || lower.contains("task") { return "task" }
            return "idea"
        }
        
        for rawLine in lines {
            let line = clean(rawLine)
            guard !line.isEmpty else { continue }
            
            if line.hasPrefix("# ") {
                // Collection title/context; ignore for node creation
                continue
            } else if line.hasPrefix("## ") {
                // Root node
                let text = clean(String(line.dropFirst(3)))
                let node = IdeaNode(
                    rawCapture: text,
                    title: text,
                    refinedText: text,
                    summary: "",
                    nodeType: inferType(from: text),
                    status: "seed",
                    parentID: nil,
                    parent: nil,
                    collectionID: collection.id,
                    collection: collection
                    
                )
                context.insert(node)
                lastRoot = node
                lastHeading = node
            } else if line.hasPrefix("### ") {
                // Child of latest root (heading-level child)
                let text = clean(String(line.dropFirst(4)))
                let node = IdeaNode(
                    rawCapture: text,
                    title: text,
                    refinedText: text,
                    summary: "",
                    nodeType: inferType(from: text),
                    status: "seed",
                    parentID: lastRoot?.id,
                    parent: lastRoot,
                    collectionID: collection.id,
                    collection: collection
                    
                )
                context.insert(node)
                lastHeading = node
            } else if line.hasPrefix("- ") {
                // Bullet: child of latest heading node
                let text = clean(String(line.dropFirst(2)))
                let node = IdeaNode(
                    rawCapture: text,
                    title: text,
                    refinedText: text,
                    summary: "",
                    nodeType: inferType(from: text),
                    status: "seed",
                    parentID: (lastHeading ?? lastRoot)?.id,
                    parent: lastHeading ?? lastRoot,
                    collectionID: collection.id,
                    collection: collection
                    
                )
                context.insert(node)
            } else {
                // Unrecognized line; ignore to keep import simple
                continue
            }
        }
        
        do {
            try context.save()
        } catch {
            // For a simple first pass, ignore errors beyond logging
#if DEBUG
            print("IdeaTreeImporter save error: \(error)")
#endif
        }
    }
    
    static func importMarkdownAsCollection(_ markdown: String, context: ModelContext, mode: ImportMode = .createNewCopy) -> IdeaCollection? {
        let normalizedMarkdown = IdeaMarkdownNormalizer.normalize(markdown)
        let lines = normalizedMarkdown.components(separatedBy: .newlines)
        
        IdeaImportDebug.log("RAW COLLECTION IMPORT", markdown)
        IdeaImportDebug.log("NORMALIZED COLLECTION IMPORT", normalizedMarkdown)
        
        func clean(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }
        func inferType(from title: String) -> String {
            let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = t.lowercased()
            if t.hasSuffix("?") || lower.contains("question") { return "question" }
            if lower.contains("decision") { return "decision" }
            if lower.contains("implemented") { return "implementation" }
            if lower.hasPrefix("build ") || lower.hasPrefix("add ") || lower.contains("task") { return "task" }
            return "idea"
        }
        
        var title: String = "Imported Outline"
        var purpose = ""
        var goals = ""
        var keyConcepts = ""
        var background = ""
        var refinement = ""
        
        // First pass: read collection metadata and title
        for raw in lines {
            let line = clean(raw)
            if line.hasPrefix("# ") { title = clean(String(line.dropFirst(2))) }
            else if line.lowercased().hasPrefix("purpose:") { purpose = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if line.lowercased().hasPrefix("goals:") { goals = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if line.lowercased().hasPrefix("key concepts:") { keyConcepts = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if line.lowercased().hasPrefix("background context:") { background = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if line.lowercased().hasPrefix("refinement instructions:") { refinement = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
        }
        
        func uniqueCollectionName(base: String, existingNames: Set<String>) -> String {
            if !existingNames.contains(base) { return base }
            var counter = 2
            while existingNames.contains("\(base) \(counter)") {
                counter += 1
            }
            return "\(base) \(counter)"
        }

        let existingFetch = FetchDescriptor<IdeaCollection>()
        let allCollections = (try? context.fetch(existingFetch)) ?? []
        let existingNames = Set(allCollections.map { $0.name })
        let existing = allCollections.first(where: { $0.name == title })

        let collection: IdeaCollection
        if let existing, mode == .replaceExisting {
            existing.summary = ""
            existing.purpose = purpose
            existing.goalsText = goals
            existing.keyConceptsText = keyConcepts
            existing.backgroundContext = background
            existing.refinementInstructions = refinement
            collection = existing

            let existingID = existing.id
            let nodesFetch = FetchDescriptor<IdeaNode>()
            let existingNodes = (try? context.fetch(nodesFetch)) ?? []
            for node in existingNodes where node.collectionID == existingID {
                context.delete(node)
            }

            do {
                try context.save()
            } catch {
#if DEBUG
                print("Save after delete failed: \(error)")
#endif
            }
        } else {
            let newName = existing == nil ? title : uniqueCollectionName(base: title, existingNames: existingNames)
            let newCollection = IdeaCollection(
                name: newName,
                summary: "",
                iconName: "lightbulb",
                purpose: purpose,
                goalsText: goals,
                keyConceptsText: keyConcepts,
                backgroundContext: background,
                refinementInstructions: refinement
            )
            context.insert(newCollection)
            collection = newCollection
        }
            
            // Track latest heading nodes by level and global sort order
            var latestNodeByLevel: [Int: IdeaNode] = [:] // 2 => ##, 3 => ###, 4 => ####
            var orderCounter: Int = 0
            
            func makeHeading(text: String, level: Int) {
                let parent: IdeaNode?
                if level <= 2 {
                    parent = nil
                } else {
                    parent = latestNodeByLevel[level - 1]
                }

                let node = IdeaNode(
                    rawCapture: text,
                    title: text,
                    refinedText: text,
                    summary: "",
                    nodeType: inferType(from: text),
                    status: "seed",
                    parentID: parent?.id,
                    collectionID: collection.id,
                    sortOrder: orderCounter
                    
                )
                orderCounter += 1

                context.insert(node)
                node.collection = collection
                if let parent {
                    node.parent = parent
                }

                latestNodeByLevel[level] = node
                for deeper in (level + 1)...6 {
                    latestNodeByLevel.removeValue(forKey: deeper)
                }
            }
            
            func makeBullet(text: String) {
                let parent = latestNodeByLevel[4] ?? latestNodeByLevel[3] ?? latestNodeByLevel[2]

                let node = IdeaNode(
                    rawCapture: text,
                    title: text,
                    refinedText: text,
                    summary: "",
                    nodeType: inferType(from: text),
                    status: "seed",
                    parentID: parent?.id,
                    collectionID: collection.id,
                    sortOrder: orderCounter
                    
                )
                orderCounter += 1

                context.insert(node)
                node.collection = collection
                if let parent {
                    node.parent = parent
                }
            }
            
            // Second pass: build outline
            for raw in lines {
                let line = clean(raw)
                guard !line.isEmpty else { continue }
                if line.hasPrefix("# ") { continue } // already handled title
                if line.lowercased().hasPrefix("purpose:") || line.lowercased().hasPrefix("goals:") || line.lowercased().hasPrefix("key concepts:") || line.lowercased().hasPrefix("background context:") || line.lowercased().hasPrefix("refinement instructions:") {
                    continue
                }
                if line.hasPrefix("## ") {
                    makeHeading(text: clean(String(line.dropFirst(3))), level: 2)
                } else if line.hasPrefix("### ") {
                    makeHeading(text: clean(String(line.dropFirst(4))), level: 3)
                } else if line.hasPrefix("#### ") {
                    makeHeading(text: clean(String(line.dropFirst(5))), level: 4)
                } else if line.hasPrefix("- ") {
                    makeBullet(text: clean(String(line.dropFirst(2))))
                }
            }
            
            do {
                try context.save()

                IdeaImportDebug.log(
                    "IMPORT SUCCESS",
                    "Collection: \(collection.name)\nNodes Imported: \(orderCounter)"
                )

                return collection
            } catch {
#if DEBUG
                print("IdeaTreeImporter save error: \(error)")
#endif
                return nil
            }
        }
    }
