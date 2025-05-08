//
//  ModoProtecaoCompletoApp.swift
//  ModoProtecaoCompleto
//
//  Created by Joana Braz de Almeida Ritter on 07/04/25.
//

import SwiftUI

@main
struct ModoProtecaoCompletoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
