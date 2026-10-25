//
//  ContactsView.swift
//  MedicalWallet
//
//  Emergency contacts for the user or a family member
//

import SwiftUI
import CoreData

struct ContactsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var contacts: FetchedResults<Contact>

    // nil = the user's own contacts
    let familyMemberID: UUID?

    @State private var showingAddSheet = false
    @State private var editingContact: Contact?
    @State private var showingError = false
    @State private var errorMessage = ""

    init(familyMemberID: UUID? = nil) {
        self.familyMemberID = familyMemberID
        _contacts = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)],
            predicate: NSPredicate.owned(by: familyMemberID),
            animation: .default)
    }

    var body: some View {
        Group {
            if contacts.isEmpty {
                ContentUnavailableView {
                    Label("No Emergency Contacts", systemImage: "phone.badge.plus")
                } description: {
                    Text("Add the people who should be called in an emergency.")
                } actions: {
                    Button("Add Contact") {
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(contacts) { contact in
                        ContactRow(contact: contact)
                            .onTapGesture {
                                editingContact = contact
                            }
                    }
                    .onDelete(perform: deleteContacts)
                }
            }
        }
        .navigationTitle("Emergency Contacts")
        .toolbar {
            Button(action: { showingAddSheet = true }) {
                Label("Add", systemImage: "plus.circle.fill")
                    .symbolRenderingMode(.multicolor)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ContactFormSheet(contact: nil, familyMemberID: familyMemberID)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingContact) { contact in
            ContactFormSheet(contact: contact, familyMemberID: familyMemberID)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("Couldn't Delete Contact", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func deleteContacts(at offsets: IndexSet) {
        withAnimation {
            offsets.map { contacts[$0] }.forEach { viewContext.delete($0) }
            do {
                try viewContext.save()
            } catch {
                viewContext.rollback()
                print("Error deleting contact: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    @ObservedObject var contact: Contact

    // tel: links only accept digits and a leading +
    private var callURL: URL? {
        guard let phone = contact.phoneNumber else { return nil }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.fill")
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name ?? "Unknown")
                    .font(.headline)
                Text([contact.relationship, contact.phoneNumber].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let callURL {
                Link(destination: callURL) {
                    Image(systemName: "phone.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Call \(contact.name ?? "contact")")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Add / Edit Contact Sheet
struct ContactFormSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // nil when adding a new contact
    let contact: Contact?
    let familyMemberID: UUID?

    @State private var name: String
    @State private var relationship: String
    @State private var phoneNumber: String
    @State private var showingError = false
    @State private var errorMessage = ""

    init(contact: Contact?, familyMemberID: UUID?) {
        self.contact = contact
        self.familyMemberID = familyMemberID
        _name = State(initialValue: contact?.name ?? "")
        _relationship = State(initialValue: contact?.relationship ?? "Spouse/Partner")
        _phoneNumber = State(initialValue: contact?.phoneNumber ?? "")
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

                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Label("Contact", systemImage: "person.crop.circle")
                }
            }
            .navigationTitle(contact == nil ? "Add Contact" : "Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.nilIfBlank == nil || phoneNumber.nilIfBlank == nil)
                }
            }
            .alert("Couldn't Save Contact", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() {
        let target = contact ?? Contact(context: viewContext)
        if contact == nil {
            target.id = UUID()
            target.dateAdded = Date()
            target.familyMemberID = familyMemberID
        }
        target.name = name.nilIfBlank
        target.relationship = relationship
        target.phoneNumber = phoneNumber.nilIfBlank

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            print("Error saving contact: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationView {
        ContactsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
