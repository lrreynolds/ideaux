import Foundation
import SwiftData

struct IdeaMarkdownNormalizer {
    static func normalize(_ markdown: String) -> String {
        var lines = markdown.components(separatedBy: .newlines)

        // Strip common markdown code fences.
        lines = lines.filter { line in
            let lower = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return lower != "```" && lower != "```markdown" && lower != "```md"
        }

        // Drop leading commentary before a likely collection title.
        while let first = lines.first,
              first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeFirst()
        }

        // If no "# " title exists, treat first non-empty plain line as collection title.
        if let firstNonEmptyIndex = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            let first = lines[firstNonEmptyIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            if !first.hasPrefix("#") && !first.lowercased().hasPrefix("purpose:") {
                lines[firstNonEmptyIndex] = "# \(first)"
            }
        }

        // If a "# " heading exists later, drop anything before it.
        if let firstHeadingIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("# ") }) {
            lines = Array(lines[firstHeadingIndex...])
        }

        // Normalize bullets while preserving indentation.
        lines = lines.map { line in
            let indent = String(line.prefix { $0 == " " || $0 == "\t" })
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("* ") { return indent + "- " + trimmed.dropFirst(2) }
            if trimmed.hasPrefix("+ ") { return indent + "- " + trimmed.dropFirst(2) }
            if trimmed.hasPrefix("• ") { return indent + "- " + trimmed.dropFirst(2) }
            return line
        }

        // Convert bare section titles followed by bullets into ## headings.
        var normalized: [String] = []

        for index in lines.indices {
            let rawLine = lines[index]
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let previous = index > lines.startIndex ? lines[lines.index(before: index)].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let next = index < lines.index(before: lines.endIndex) ? lines[lines.index(after: index)].trimmingCharacters(in: .whitespacesAndNewlines) : ""

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
                normalized.append(rawLine)
            }
        }

        // Remove empty leading/trailing lines.
        while normalized.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            normalized.removeFirst()
        }
        while normalized.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
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
        var lastCreatedNode: IdeaNode? = nil
        
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
                lastCreatedNode = node
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
                lastCreatedNode = node
            } else if line.hasPrefix("- ") {
                let text = clean(String(line.dropFirst(2)))

                if applyInlineMetadata(text, to: lastCreatedNode) {
                    continue
                }

                // Bullet: child of latest heading node
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
                lastCreatedNode = node
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
        var goals = ""
        var keyConcepts = ""
        var background = ""
        var refinement = ""
        var collectionSummary = ""
        
        // First pass: read collection metadata and title
        for raw in lines {
            let line = clean(raw)
            if line.hasPrefix("# ") { title = clean(String(line.dropFirst(2))) }
            else if line.lowercased().hasPrefix("goals:") { goals = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if line.lowercased().hasPrefix("key concepts:") { keyConcepts = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if line.lowercased().hasPrefix("background context:") { background = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if line.lowercased().hasPrefix("refinement instructions:") { refinement = clean(String(line.split(separator: ":", maxSplits: 1).last ?? "")) }
            else if !line.isEmpty && !line.hasPrefix("#") && !line.hasPrefix("-") && collectionSummary.isEmpty { collectionSummary = line }
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
            existing.summary = collectionSummary
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
                summary: collectionSummary,
                iconName: "lightbulb",
                goalsText: goals,
                keyConceptsText: keyConcepts,
                backgroundContext: background,
                refinementInstructions: refinement
            )
            context.insert(newCollection)
            collection = newCollection
        }
            
            // Track latest heading nodes by level and global sort order
        var latestNodeByLevel: [Int: IdeaNode] = [:]
        var latestBulletByIndent: [Int: IdeaNode] = [:]
        var orderCounter: Int = 0
        var lastCreatedNode: IdeaNode? = nil
        
            func bulletIndentLevel(from raw: String) -> Int {
                let leadingWhitespace = raw.prefix { $0 == " " || $0 == "\t" }
                return leadingWhitespace.reduce(0) { total, character in
                total + (character == "\t" ? 4 : 1)
            }
        }
            
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

                lastCreatedNode = node
                latestNodeByLevel[level] = node
                for deeper in (level + 1)...6 {
                    latestNodeByLevel.removeValue(forKey: deeper)
                }
                latestBulletByIndent.removeAll()
            }
            
        func makeBullet(text: String, indentLevel: Int) {
                if applyInlineMetadata(text, to: lastCreatedNode) {
                    return
                }

            let parentFromIndent = latestBulletByIndent
                .filter { $0.key < indentLevel }
                .sorted { $0.key > $1.key }
                .first?.value
            
             let parent = parentFromIndent ?? latestNodeByLevel[4] ?? latestNodeByLevel[3] ?? latestNodeByLevel[2]
            
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

                lastCreatedNode = node
            latestBulletByIndent[indentLevel] = node

            for deeperIndent in latestBulletByIndent.keys where deeperIndent > indentLevel {
                latestBulletByIndent.removeValue(forKey: deeperIndent)
            }
            }
            
            // Second pass: build outline
            for raw in lines {
                let indentLevel = bulletIndentLevel(from: raw)
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
                    makeBullet(text: clean(String(line.dropFirst(2))), indentLevel: indentLevel)
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

    private static func applyInlineMetadata(_ text: String, to node: IdeaNode?) -> Bool {
        guard let node else { return false }

        let lower = text.lowercased()

        if lower.hasPrefix("summary:") {
            let value = String(text.dropFirst("Summary:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return true }

            node.refinedText = value
            node.summary = value
            node.updatedAt = Date()
            return true
        }

        if lower.hasPrefix("refined:") {
            let value = String(text.dropFirst("Refined:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return true }

            node.refinedText = value
            node.summary = value
            node.updatedAt = Date()
            return true
        }

        if lower.hasPrefix("original:") {
            let value = String(text.dropFirst("Original:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return true }

            node.rawCapture = value
            node.updatedAt = Date()
            return true
        }

        return false
    }
}
