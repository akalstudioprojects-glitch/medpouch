//
//  ContentView.swift
//  MedicalWallet
//
//  Main tab bar
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            MedicationsView()
                .tabItem {
                    Label("Medications", systemImage: "pills.fill")
                }

            NavigationView {
                PrescriptionsView()
            }
            .tabItem {
                Label("Prescriptions", systemImage: "doc.text.fill")
            }

            NavigationView {
                WalletCardView()
            }
            .tabItem {
                Label("Emergency", systemImage: "staroflife.fill")
            }

            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
