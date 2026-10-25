//
//  FamilyMembersView.swift
//  MedicalWallet
//
//  Family members and their medical records
//

import SwiftUI
import CoreData

struct FamilyMembersView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FamilyMember.dateAdded, ascending: true)],
        animation: .default)
    private var familyMembers: FetchedResults<FamilyMember>

    @State private var showingAddSheet = false
    @State private var memberToDelete: FamilyMember?
    @State private var showingError = false
    @State private var errorMessage = ""

    private var showingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { memberToDelete != nil },
            set: { if !$0 { memberToDelete = nil } }
        )
    }

    var body: some View {
        Group {
            if familyMembers.isEmpty {
                ContentUnavailableView {
                    Label("No Family Members", systemImage: "person.3.fill")
                } description: {
                    Text("Keep medications, allergies, and emergency details for the people you care for.")
                } actions: {
                    Button("Add Family Member") {
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(familyMembers) { member in
                        if let memberID = member.id {
                            NavigationLink {
                                FamilyMemberDetailView(member: member, memberID: memberID)
                            } label: {
                                FamilyMemberRow(member: member)
                            }
                            .swipeActions {
                                Button {
                                    memberToDelete = member
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Family Members")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add", systemImage: "person.badge.plus")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            FamilyMemberFormSheet(member: nil)
                .environment(\.managedObjectContext, viewContext)
        }
        .confirmationDialog(
            "Delete \(memberToDelete?.name ?? "Family Member")?",
            isPresented: showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let member = memberToDelete {
                    deleteMember(member)
                }
            }
        } message: {
            Text("This also deletes their medications, prescriptions, allergies, contacts, and reminders.")
        }
        .alert("Couldn't Delete Family Member", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func deleteMember(_ member: FamilyMember) {
        withAnimation {
            do {
                try viewContext.deleteFamilyMember(member)
            } catch {
                viewContext.rollback()
                print("Error deleting family member: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        memberToDelete = nil
    }
}

// MARK: - Family Member Row
struct FamilyMemberRow: View {
    @ObservedObject var member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Text(String((member.name ?? "?").prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name ?? "Unknown")
                    .font(.headline)
                if let relationship = member.relationship {
                    Text(relationship)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Family Member Detail
struct FamilyMemberDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var member: FamilyMember
    let memberID: UUID

    @State private var showingEditSheet = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    FamilyMemberRow(member: member)
                    Spacer()
                }

                if let dateOfBirth = member.dateOfBirth {
                    LabeledContent("Date of Birth", value: dateOfBirth.formatted(date: .long, time: .omitted))
                }
                if let bloodType = member.bloodType, bloodType != "Unknown" {
                    LabeledContent("Blood Type", value: bloodType)
                }
                if let conditions = member.medicalConditions {
                    LabeledContent("Conditions", value: conditions)
                }
                if let notes = member.notes {
                    LabeledContent("Notes", value: notes)
                }
            }

            Section {
                NavigationLink(destination: MedicationsView(familyMemberID: memberID, isPushed: true)) {
                    Label("Medications", systemImage: "pills.fill")
                }
                NavigationLink(destination: PrescriptionsView(familyMemberID: memberID)) {
                    Label("Prescriptions", systemImage: "doc.text.fill")
                }
                NavigationLink(destination: AllergiesView(familyMemberID: memberID)) {
                    Label("Allergies", systemImage: "allergens")
                }
                NavigationLink(destination: ContactsView(familyMemberID: memberID)) {
                    Label("Emergency Contacts", systemImage: "phone.fill")
                }
                NavigationLink(destination: WalletCardView(member: member)) {
                    Label("Emergency Card", systemImage: "staroflife.fill")
                }
            } header: {
                Text("Health Records")
            }
        }
        .navigationTitle(member.name ?? "Family Member")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                showingEditSheet = true
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            FamilyMemberFormSheet(member: member)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// MARK: - Add / Edit Family Member Sheet
struct FamilyMemberFormSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // nil when adding a new family member
    let member: FamilyMember?

    @State private var name: String
    @State private var relationship: String
    @State private var hasDateOfBirth: Bool
    @State private var dateOfBirth: Date
    @State private var bloodType: String
    @State private var medicalConditions: String
    @State private var notes: String
    @State private var showingError = false
    @State private var errorMessage = ""

    init(member: FamilyMember?) {
        self.member = member
        _name = State(initialValue: member?.name ?? "")
        _relationship = State(initialValue: member?.relationship ?? "Child")
        _hasDateOfBirth = State(initialValue: member?.dateOfBirth != nil)
        _dateOfBirth = State(initialValue: member?.dateOfBirth ?? Date())
        _bloodType = State(initialValue: member?.bloodType ?? "Unknown")
        _medicalConditions = State(initialValue: member?.medicalConditions ?? "")
        _notes = State(initialValue: member?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    Picker("Relationship", selection: $relationship) {
                        ForEach(MedicalOptions.relationships, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }

                    Toggle("Add Date of Birth", isOn: $hasDateOfBirth)
                    if hasDateOfBirth {
                        DatePicker("Date of Birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                    }
                } header: {
                    Label("About", systemImage: "person.fill")
                }

                Section {
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(MedicalOptions.bloodTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }

                    TextField("Medical conditions", text: $medicalConditions, axis: .vertical)
                        .lineLimit(1...4)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                } header: {
                    Label("Medical Information", systemImage: "cross.case.fill")
                }
            }
            .navigationTitle(member == nil ? "Add Family Member" : "Edit Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.nilIfBlank == nil)
                }
            }
            .alert("Couldn't Save Family Member", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() {
        let target = member ?? FamilyMember(context: viewContext)
        if member == nil {
            target.id = UUID()
            target.dateAdded = Date()
        }
        target.name = name.nilIfBlank
        target.relationship = relationship
        target.dateOfBirth = hasDateOfBirth ? dateOfBirth : nil
        target.bloodType = bloodType
        target.medicalConditions = medicalConditions.nilIfBlank
        target.notes = notes.nilIfBlank

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            print("Error saving family member: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        FamilyMembersView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
