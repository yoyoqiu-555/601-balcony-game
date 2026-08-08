//
//  _01______App.swift
//  601号阳台 游戏
//
//  Created by student07 on 2026/5/23.
//

import SwiftUI

@main
struct _01______App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            OpeningRootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
