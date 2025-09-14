//
//  BookFinderApp.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 13/09/25.
//

import SwiftUI

@main
struct BookFinderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SearchView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
