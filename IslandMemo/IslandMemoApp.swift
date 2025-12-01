//
//  islandmemoApp.swift
//  islandmemo
//
//  Created by 구민준 on 11/26/25.
//
import SwiftUI
import SwiftData

@main
struct IslandMemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: LinkItem.self)
    }
}
