//
//  AllergiesView.swift
//  MedicalWallet
//
//  Allergies for the user or a family member
//

import SwiftUI
import CoreData

struct AllergiesView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var allergies: FetchedResults<Allergy>

    // nil = the user's own allergies
    let familyMemberID: UUID?

    @State private var showingAddSheet = false
    @State private var editingAllergy: Allergy?
    @State private var showingError = false
    @State private var errorMessage = ""

    static let noKnownAllergies = "No Known Allergies"

    init(familyMemberID: UUID? = nil) {
        self.familyMemberID = familyMemberID
        _allergies = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Allergy.dateAdded, ascending: false)],
            predicate: NSPredicate.owned(by: familyMemberID),
            animation: .default)
    }

    var body: some View {
        Group {
            if allergies.isEmpty {
                ContentUnavailableView {
                    Label("No Allergies Added", systemImage: "allergens")
                } description: {
                    Text("Allergies appear on the emergency card so first responders can see them.")
                } actions: {
                    Button("Add Allergy") {
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("I Have No Known Allergies") {
                        addNoKnownAllergies()
                    }
                }
            } else {
                List {
                    ForEach(allergies) { allergy in
                        Button {
                            editingAllergy = allergy
                        } label: {
                            AllergyRow(allergy: allergy)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteAllergies)
                }
            }
        }
        .navigationTitle("Allergies")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add", systemImage: "plus.circle.fill")
                    .symbolRenderingMode(.multicolor)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AllergyFormSheet(allergy: nil, familyMemberID: familyMemberID)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingAllergy) { allergy in
            AllergyFormSheet(allergy: allergy, familyMemberID: familyMemberID)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Something Went Wrong", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func addNoKnownAllergies() {
        let allergy = Allergy(context: viewContext)
        allergy.id = UUID()
        allergy.allergen = Self.noKnownAllergies
        allergy.dateAdded = Date()
        allergy.familyMemberID = familyMemberID
        saveContext()
    }

    private func deleteAllergies(at offsets: IndexSet) {
        withAnimation {
            offsets.map { allergies[$0] }.forEach { viewContext.delete($0) }
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            print("Error saving allergies: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Allergy Row
struct AllergyRow: View {
    @ObservedObject var allergy: Allergy

    private var severityColor: Color {
        switch allergy.severity ?? "" {
        case "Life-threatening": return .red
        case "Severe": return .orange
        case "Moderate": return .yellow
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: allergy.allergen == AllergiesView.noKnownAllergies ? "checkmark.shield.fill" : "allergens")
                    .foregroundColor(severityColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(allergy.allergen ?? "Unknown")
                    .font(.headline)
                if let reaction = allergy.reaction {
                    Text(reaction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let severity = allergy.severity {
                Text(severity)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Add / Edit Allergy Sheet
struct AllergyFormSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // nil when adding a new allergy
    let allergy: Allergy?
    let familyMemberID: UUID?

    @State private var allergen: String
    @State private var severity: String
    @State private var reaction: String
    @State private var showingError = false
    @State private var errorMessage = ""

    init(allergy: Allergy?, familyMemberID: UUID?) {
        self.allergy = allergy
        self.familyMemberID = familyMemberID
        _allergen = State(initialValue: allergy?.allergen ?? "")
        _severity = State(initialValue: allergy?.severity ?? "Moderate")
        _reaction = State(initialValue: allergy?.reaction ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Allergen (e.g., Penicillin, Peanuts)", text: $allergen)

                    Picker("Severity", selection: $severity) {
                        ForEach(MedicalOptions.allergySeverities, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }

                    TextField("Reaction (e.g., Hives, Swelling)", text: $reaction, axis: .vertical)
                        .lineLimit(1...4)
                } header: {
                    Label("Allergy", systemImage: "allergens")
                }
            }
            .navigationTitle(allergy == nil ? "Add Allergy" : "Edit Allergy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(allergen.nilIfBlank == nil)
                }
            }
            .alert("Couldn't Save Allergy", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() {
        let target = allergy ?? Allergy(context: viewContext)
        if allergy == nil {
            target.id = UUID()
            target.dateAdded = Date()
            target.familyMemberID = familyMemberID
        }
        target.allergen = allergen.nilIfBlank
        target.severity = severity
        target.reaction = reaction.nilIfBlank

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            print("Error saving allergy: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        AllergiesView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
