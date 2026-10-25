//
//  MedicationsView.swift
//  MedicalWallet
//
//  Essential Medications Management
//

import SwiftUI
import CoreData

struct MedicationsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Essential medications first, then the rest alphabetically
    @FetchRequest private var medications: FetchedResults<Medication>

    // nil = the user's own medications
    let familyMemberID: UUID?
    // True when pushed onto an existing navigation stack (e.g. from Home), so we don't nest a second NavigationView
    let isPushed: Bool
    // Opens the Add Medication sheet as soon as the screen appears
    let opensAddSheetOnAppear: Bool

    @State private var showingAddSheet = false
    @State private var editingMedication: Medication?
    @State private var hasOpenedInitialSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(familyMemberID: UUID? = nil, isPushed: Bool = false, opensAddSheetOnAppear: Bool = false) {
        self.familyMemberID = familyMemberID
        self.isPushed = isPushed
        self.opensAddSheetOnAppear = opensAddSheetOnAppear
        _medications = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Medication.isEssential, ascending: false),
                NSSortDescriptor(keyPath: \Medication.name, ascending: true)
            ],
            predicate: NSPredicate.owned(by: familyMemberID),
            animation: .default)
    }

    private var essentialCount: Int {
        medications.filter { $0.isEssential }.count
    }

    var body: some View {
        if isPushed {
            content
        } else {
            NavigationView {
                content
            }
        }
    }

    private var content: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.05),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if medications.isEmpty {
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.green.opacity(0.3), .blue.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)

                            Image(systemName: "pills.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 40)

                        VStack(spacing: 12) {
                            Text("No Medications Yet")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Add medications you take regularly")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Info cards
                        VStack(spacing: 12) {
                            InfoCard(
                                icon: "star.fill",
                                title: "Track Important Meds",
                                description: "Keep a list of medications you take daily",
                                color: .yellow
                            )

                            InfoCard(
                                icon: "heart.text.square.fill",
                                title: "Emergency Ready",
                                description: "Appears on your emergency wallet card",
                                color: .red
                            )

                            InfoCard(
                                icon: "bell.fill",
                                title: "Never Forget",
                                description: "Set reminders for when to take them",
                                color: .blue
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header description
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .blue]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)

                                Image(systemName: "list.star")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Medications")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("\(medications.count) saved · \(essentialCount) essential")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.top)

                        // Medications list
                        ForEach(medications) { medication in
                            VStack(alignment: .leading, spacing: 12) {
                                // Header with name and star
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "pills.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)

                                        Text(medication.name ?? "Unknown")
                                            .font(.headline)
                                    }

                                    Spacer()

                                    if medication.isEssential {
                                        Image(systemName: "star.fill")
                                            .font(.callout)
                                            .foregroundColor(.yellow)
                                    }
                                }

                                // Dosage
                                if let dosage = medication.dosage, !dosage.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cross.vial")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .frame(width: 20)
                                        Text("Dosage:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(dosage)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Frequency
                                if let frequency = medication.frequency, !frequency.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.fill")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                            .frame(width: 20)
                                        Text("Frequency:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(frequency)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                }

                                // Notes
                                if let notes = medication.notes, !notes.isEmpty {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "note.text")
                                            .font(.subheadline)
                                            .foregroundColor(.purple)
                                            .frame(width: 20)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Notes:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(notes)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .green.opacity(0.1), radius: 5, x: 0, y: 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingMedication = medication
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteMedication(medication)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Medications")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add", systemImage: "plus.circle.fill")
                    .symbolRenderingMode(.multicolor)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMedicationSheet(familyMemberID: familyMemberID)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingMedication) { medication in
            EditMedicationSheet(medication: medication)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Couldn't Delete Medication", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if opensAddSheetOnAppear && !hasOpenedInitialSheet {
                hasOpenedInitialSheet = true
                showingAddSheet = true
            }
        }
    }

    private func deleteMedication(_ medication: Medication) {
        let medID = medication.id

        withAnimation {
            viewContext.delete(medication)
            do {
                try viewContext.save()

                // Cancel any scheduled notifications
                if let medID = medID {
                    NotificationManager.shared.cancelMedicationReminder(medicationID: medID)
                }
            } catch {
                viewContext.rollback()
                print("Error deleting medication: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Info Card Component
struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AddMedicationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // nil = the user's own medication
    let familyMemberID: UUID?

    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    @State private var notes = ""
    @State private var isEssential = true
    @State private var showingError = false
    @State private var errorMessage = ""

    let frequencies = ["As needed", "Daily", "Twice daily", "Three times daily", "Weekly", "Other"]

    init(familyMemberID: UUID? = nil) {
        self.familyMemberID = familyMemberID
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "pills.circle.fill")
                            .foregroundColor(.green)
                        TextField("Medication Name", text: $medicationName)
                    }

                    HStack {
                        Image(systemName: "cross.vial")
                            .foregroundColor(.blue)
                        TextField("Dosage (e.g., 50mg, 1 tablet)", text: $dosage)
                    }
                } header: {
                    Label("Medication Information", systemImage: "cross.case.fill")
                }

                Section {
                    Picker(selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            HStack {
                                Image(systemName: "clock.fill")
                                Text(freq)
                            }
                            .tag(freq)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("Frequency")
                        }
                    }
                } header: {
                    Label("How Often", systemImage: "calendar")
                } footer: {
                    Text(NotificationManager.reminderDescription(for: frequency))
                        .font(.caption)
                }

                Section {
                    Toggle(isOn: $isEssential) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Mark as Essential")
                        }
                    }
                } footer: {
                    Text("Essential medications appear on the emergency wallet card")
                        .font(.caption)
                }

                Section {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(.purple)
                            .padding(.top, 8)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                    }
                } header: {
                    Label("Notes (Optional)", systemImage: "note.text")
                } footer: {
                    Text("Add any special instructions or reminders")
                        .font(.caption)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .alert("Couldn't Save Medication", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var trimmedName: String {
        medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveMedication() {
        let newMedication = Medication(context: viewContext)
        let medicationID = UUID()
        newMedication.id = medicationID
        newMedication.name = trimmedName
        newMedication.dosage = dosage.isEmpty ? nil : dosage
        newMedication.frequency = frequency
        newMedication.notes = notes.isEmpty ? nil : notes
        newMedication.isEssential = isEssential
        newMedication.dateAdded = Date()
        newMedication.familyMemberID = familyMemberID // nil = user's own medication

        do {
            try viewContext.save()

            // Schedule notification reminder if frequency is not "As needed"
            if frequency.lowercased() != "as needed" {
                NotificationManager.shared.scheduleMedicationReminder(
                    medicationName: trimmedName,
                    medicationID: medicationID,
                    frequency: frequency
                )
            }

            dismiss()
        } catch {
            viewContext.rollback()
            print("Error saving medication: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Edit Medication Sheet
struct EditMedicationSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let medication: Medication

    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    @State private var notes = ""
    @State private var isEssential = true
    @State private var showingDeleteAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""

    let frequencies = ["As needed", "Daily", "Twice daily", "Three times daily", "Weekly", "Other"]

    init(medication: Medication) {
        self.medication = medication
        _medicationName = State(initialValue: medication.name ?? "")
        _dosage = State(initialValue: medication.dosage ?? "")
        _frequency = State(initialValue: medication.frequency ?? "Daily")
        _notes = State(initialValue: medication.notes ?? "")
        _isEssential = State(initialValue: medication.isEssential)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "pills.circle.fill")
                            .foregroundColor(.green)
                        TextField("Medication Name", text: $medicationName)
                    }

                    HStack {
                        Image(systemName: "cross.vial")
                            .foregroundColor(.blue)
                        TextField("Dosage (e.g., 50mg, 1 tablet)", text: $dosage)
                    }
                } header: {
                    Label("Medication Information", systemImage: "cross.case.fill")
                }

                Section {
                    Picker(selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            HStack {
                                Image(systemName: "clock.fill")
                                Text(freq)
                            }
                            .tag(freq)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("Frequency")
                        }
                    }
                } header: {
                    Label("How Often", systemImage: "calendar")
                } footer: {
                    Text(NotificationManager.reminderDescription(for: frequency))
                        .font(.caption)
                }

                Section {
                    Toggle(isOn: $isEssential) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Mark as Essential")
                        }
                    }
                } footer: {
                    Text("Essential medications appear on your emergency wallet card")
                        .font(.caption)
                }

                Section {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(.purple)
                            .padding(.top, 8)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                    }
                } header: {
                    Label("Notes (Optional)", systemImage: "note.text")
                } footer: {
                    Text("Add any special instructions or reminders")
                        .font(.caption)
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Medication", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .alert("Delete Medication?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteMedication()
                }
            } message: {
                Text("Are you sure you want to delete this medication? This cannot be undone.")
            }
        }
        // Attached outside the Form so it doesn't clash with the delete alert above
        .alert("Something Went Wrong", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var trimmedName: String {
        medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveChanges() {
        medication.name = trimmedName
        medication.dosage = dosage.isEmpty ? nil : dosage
        medication.frequency = frequency
        medication.notes = notes.isEmpty ? nil : notes
        medication.isEssential = isEssential

        do {
            try viewContext.save()

            // Reschedule notifications with new frequency
            if let medID = medication.id {
                if frequency.lowercased() != "as needed" {
                    NotificationManager.shared.rescheduleMedicationReminder(
                        medicationName: trimmedName,
                        medicationID: medID,
                        frequency: frequency
                    )
                } else {
                    // Cancel notifications if changed to "As needed"
                    NotificationManager.shared.cancelMedicationReminder(medicationID: medID)
                }
            }

            dismiss()
        } catch {
            viewContext.rollback()
            print("Error updating medication: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func deleteMedication() {
        let medID = medication.id

        viewContext.delete(medication)

        do {
            try viewContext.save()

            // Cancel any scheduled notifications
            if let medID = medID {
                NotificationManager.shared.cancelMedicationReminder(medicationID: medID)
            }

            dismiss()
        } catch {
            viewContext.rollback()
            print("Error deleting medication: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    MedicationsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
