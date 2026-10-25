//
//  PrescriptionsView.swift
//  MedicalWallet
//
//  Saved prescriptions with optional photos
//

import SwiftUI
import CoreData
import PhotosUI

struct PrescriptionsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var prescriptions: FetchedResults<Prescription>

    // nil = the user's own prescriptions
    let familyMemberID: UUID?
    // Opens the Add Prescription sheet as soon as the screen appears
    let opensAddSheetOnAppear: Bool

    @State private var showingAddSheet = false
    @State private var editingPrescription: Prescription?
    @State private var hasOpenedInitialSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(familyMemberID: UUID? = nil, opensAddSheetOnAppear: Bool = false) {
        self.familyMemberID = familyMemberID
        self.opensAddSheetOnAppear = opensAddSheetOnAppear
        _prescriptions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Prescription.dateAdded, ascending: false)],
            predicate: NSPredicate.owned(by: familyMemberID),
            animation: .default)
    }

    var body: some View {
        Group {
            if prescriptions.isEmpty {
                ContentUnavailableView {
                    Label("No Prescriptions Yet", systemImage: "doc.text.magnifyingglass")
                } description: {
                    Text("Save your prescriptions with a photo so you always have a copy on hand.")
                } actions: {
                    Button("Add Prescription") {
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(prescriptions) { prescription in
                        Button {
                            editingPrescription = prescription
                        } label: {
                            PrescriptionRow(prescription: prescription)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deletePrescriptions)
                }
            }
        }
        .navigationTitle("Prescriptions")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add", systemImage: "plus.circle.fill")
                    .symbolRenderingMode(.multicolor)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            PrescriptionFormSheet(prescription: nil, familyMemberID: familyMemberID)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingPrescription) { prescription in
            PrescriptionFormSheet(prescription: prescription, familyMemberID: familyMemberID)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Couldn't Delete Prescription", isPresented: $showingError) {
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

    private func deletePrescriptions(at offsets: IndexSet) {
        withAnimation {
            offsets.map { prescriptions[$0] }.forEach { viewContext.delete($0) }
            do {
                try viewContext.save()
            } catch {
                viewContext.rollback()
                print("Error deleting prescription: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Prescription Row
struct PrescriptionRow: View {
    @ObservedObject var prescription: Prescription

    var body: some View {
        HStack(spacing: 12) {
            if let data = prescription.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.medicationName ?? "Unknown")
                    .font(.headline)

                if let dosage = prescription.dosage {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let doctor = prescription.doctorName {
                    HStack(spacing: 4) {
                        Image(systemName: "stethoscope")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(doctor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let date = prescription.dateIssued ?? prescription.dateAdded {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Add / Edit Prescription Sheet
struct PrescriptionFormSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // nil when adding a new prescription
    let prescription: Prescription?
    let familyMemberID: UUID?

    @State private var medicationName: String
    @State private var dosage: String
    @State private var doctorName: String
    @State private var pharmacy: String
    @State private var instructions: String
    @State private var dateIssued: Date
    @State private var refillsRemaining: Int
    @State private var notes: String
    @State private var imageData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingDeleteAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(prescription: Prescription?, familyMemberID: UUID?) {
        self.prescription = prescription
        self.familyMemberID = familyMemberID
        _medicationName = State(initialValue: prescription?.medicationName ?? "")
        _dosage = State(initialValue: prescription?.dosage ?? "")
        _doctorName = State(initialValue: prescription?.doctorName ?? "")
        _pharmacy = State(initialValue: prescription?.pharmacy ?? "")
        _instructions = State(initialValue: prescription?.instructions ?? "")
        _dateIssued = State(initialValue: prescription?.dateIssued ?? Date())
        _refillsRemaining = State(initialValue: Int(prescription?.refillsRemaining ?? 0))
        _notes = State(initialValue: prescription?.notes ?? "")
        _imageData = State(initialValue: prescription?.imageData)
    }

    private var isEditing: Bool {
        prescription != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "pills.circle.fill")
                            .foregroundColor(.blue)
                        TextField("Medication Name", text: $medicationName)
                    }

                    HStack {
                        Image(systemName: "cross.vial")
                            .foregroundColor(.blue)
                        TextField("Dosage (e.g., 500mg)", text: $dosage)
                    }
                } header: {
                    Label("Medication", systemImage: "cross.case.fill")
                }

                Section {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.purple)
                        TextField("Doctor", text: $doctorName)
                    }

                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.green)
                        TextField("Pharmacy", text: $pharmacy)
                    }

                    DatePicker("Date Issued", selection: $dateIssued, in: ...Date(), displayedComponents: .date)

                    Stepper("Refills Remaining: \(refillsRemaining)", value: $refillsRemaining, in: 0...99)
                } header: {
                    Label("Details", systemImage: "doc.text.fill")
                }

                Section {
                    TextField("e.g., Take 1 tablet with food", text: $instructions, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Label("Instructions", systemImage: "list.bullet.clipboard")
                }

                Section {
                    if let imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button(role: .destructive) {
                            self.imageData = nil
                            photoItem = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(imageData == nil ? "Choose Photo" : "Replace Photo", systemImage: "photo.on.rectangle")
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                        }
                    }
                } header: {
                    Label("Photo", systemImage: "camera")
                } footer: {
                    Text("Photos are stored only on this device.")
                        .font(.caption)
                }

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Label("Notes (Optional)", systemImage: "note.text")
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Prescription", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Prescription" : "Add Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(medicationName.nilIfBlank == nil)
                }
            }
            .alert("Delete Prescription?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePrescription()
                }
            } message: {
                Text("Are you sure you want to delete this prescription? This cannot be undone.")
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        imageData = ImageUtils.compressedJPEG(from: data)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker(isPresented: $showingCamera) { image in
                    imageData = ImageUtils.compressedJPEG(from: image)
                }
                .ignoresSafeArea()
            }
        }
        // Attached outside the Form so it doesn't clash with the delete alert above
        .alert("Something Went Wrong", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func save() {
        let target = prescription ?? Prescription(context: viewContext)
        if prescription == nil {
            target.id = UUID()
            target.dateAdded = Date()
            target.familyMemberID = familyMemberID
        }

        target.medicationName = medicationName.nilIfBlank
        target.dosage = dosage.nilIfBlank
        target.doctorName = doctorName.nilIfBlank
        target.pharmacy = pharmacy.nilIfBlank
        target.instructions = instructions.nilIfBlank
        target.dateIssued = dateIssued
        target.refillsRemaining = Int16(refillsRemaining)
        target.notes = notes.nilIfBlank
        target.imageData = imageData

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            print("Error saving prescription: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func deletePrescription() {
        guard let prescription else { return }
        viewContext.delete(prescription)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            print("Error deleting prescription: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        PrescriptionsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
