//
//  ProfileView.swift
//  MedicalWallet
//
//  The user's own medical profile and links to the rest of their records
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("fullName") private var fullName = ""
    @AppStorage("dateOfBirth") private var dateOfBirth: Double = 0 // 0 = not set
    @AppStorage("bloodType") private var bloodType = "Unknown"
    @AppStorage("medicalConditions") private var medicalConditions = ""
    @AppStorage("isOrganDonor") private var isOrganDonor = false

    private var dateOfBirthBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: dateOfBirth) },
            set: { dateOfBirth = $0.timeIntervalSince1970 }
        )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                }

                if dateOfBirth == 0 {
                    Button {
                        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())?.timeIntervalSince1970 ?? 0
                    } label: {
                        Label("Add Date of Birth", systemImage: "calendar.badge.plus")
                    }
                } else {
                    DatePicker(selection: dateOfBirthBinding, in: ...Date(), displayedComponents: .date) {
                        Label("Date of Birth", systemImage: "calendar")
                    }
                }
            } header: {
                Label("About You", systemImage: "person.text.rectangle")
            }

            Section {
                Picker(selection: $bloodType) {
                    ForEach(MedicalOptions.bloodTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                } label: {
                    Label("Blood Type", systemImage: "drop.fill")
                }

                TextField("Medical conditions (e.g., Asthma, Diabetes)", text: $medicalConditions, axis: .vertical)
                    .lineLimit(1...4)

                Toggle(isOn: $isOrganDonor) {
                    Label("Organ Donor", systemImage: "heart.fill")
                }
            } header: {
                Label("Medical Information", systemImage: "cross.case.fill")
            } footer: {
                Text("This information appears on your emergency card.")
                    .font(.caption)
            }

            Section {
                NavigationLink(destination: AllergiesView()) {
                    Label("Allergies", systemImage: "allergens")
                }
                NavigationLink(destination: ContactsView()) {
                    Label("Emergency Contacts", systemImage: "phone.fill")
                }
                NavigationLink(destination: FamilyMembersView()) {
                    Label("Family Members", systemImage: "person.3.fill")
                }
                NavigationLink(destination: TravelMedsView()) {
                    Label("Travel Meds", systemImage: "globe.americas.fill")
                }
            } header: {
                Label("Health Records", systemImage: "folder.fill")
            }

            Section {
                NavigationLink(destination: PrivacyAndDataView()) {
                    Label("Privacy & Data", systemImage: "lock.shield.fill")
                }
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("App", systemImage: "gearshape.fill")
            }
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
