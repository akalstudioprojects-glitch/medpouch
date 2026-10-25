//
//  PrivacyAndDataView.swift
//  MedicalWallet
//
//  Medical disclaimer, privacy policy link, and delete-all-data
//  (required for health apps under App Store Guidelines 1.4.1 and 5.1)
//

import SwiftUI
import CoreData

struct PrivacyAndDataView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // TODO: Replace with your hosted privacy policy URL before submitting to the App Store
    private let privacyPolicyURL = URL(string: "https://example.com/medpouch/privacy")!

    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section {
                Text("MedPouch helps you keep track of your own medical information. It does not provide medical advice, diagnosis, or treatment. Always follow the guidance of your doctor or pharmacist, and in an emergency contact your local emergency services.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Label("Medical Disclaimer", systemImage: "cross.case.fill")
            }

            Section {
                Label("Stored only on this iPhone, encrypted when locked", systemImage: "iphone")
                Label("No accounts, no servers, no tracking", systemImage: "hand.raised.fill")
                Link(destination: privacyPolicyURL) {
                    Label("Privacy Policy", systemImage: "doc.text.fill")
                }
            } header: {
                Label("Privacy", systemImage: "lock.fill")
            } footer: {
                Text("Your information is included in your iPhone's own backups if you use them. Deleting the app deletes its data from this device.")
                    .font(.caption)
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete All Data", systemImage: "trash")
                        Spacer()
                    }
                }
                .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete Everything", role: .destructive) {
                        deleteAllData()
                    }
                } message: {
                    Text("This permanently removes all prescriptions, medications, allergies, contacts, family members, and reminders. This cannot be undone.")
                }
            } footer: {
                Text("Removes all of your MedPouch information from this device and returns the app to its welcome screen.")
                    .font(.caption)
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't Delete Data", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func deleteAllData() {
        let requests: [NSFetchRequest<NSFetchRequestResult>] = [
            Prescription.fetchRequest(),
            Medication.fetchRequest(),
            Allergy.fetchRequest(),
            Contact.fetchRequest(),
            FamilyMember.fetchRequest()
        ]

        do {
            for request in requests {
                request.includesPropertyValues = false
                let objects = try viewContext.fetch(request) as? [NSManagedObject] ?? []
                objects.forEach { viewContext.delete($0) }
            }
            try viewContext.save()

            NotificationManager.shared.cancelAllReminders()

            // Resetting hasCompletedOnboarding sends the app back to the welcome screen
            SettingsKeys.all.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        } catch {
            viewContext.rollback()
            print("Error deleting all data: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        PrivacyAndDataView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
