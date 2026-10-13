//
//  ContentView.swift
//  bearsapp
//
//  Created by Irina on 17.09.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "house") {
                TodayView()
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarView()
            }
            Tab("Goals", systemImage: "target") {
                GoalView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
