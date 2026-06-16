//
//  ideauxApp.swift
//  ideaux
//
//  Created by LouR on 6/16/26.
//

import SwiftUI
import SwiftData

@main
struct ideauxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [IdeaNode.self, IdeaProject.self, IdeaLink.self])
    }
}
