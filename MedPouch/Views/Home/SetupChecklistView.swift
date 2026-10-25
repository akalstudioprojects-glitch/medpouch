//
//  SetupChecklistView.swift
//  MedicalWallet
//
//  Home screen card that guides the user through filling in their emergency details
//

import SwiftUI
import CoreData

struct SetupChecklistView: View {
    @AppStorage("fullName") private var fullName = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Medication.name, ascending: true)],
        predicate: NSPredicate(format: "isEssential == YES AND familyMemberID == nil"))
    private var essentialMedications: FetchedResults<Medication>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Allergy.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "familyMemberID == nil"))
    private var allergies: FetchedResults<Allergy>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)],
        predicate: NSPredicate(format: "familyMemberID == nil"))
    private var contacts: FetchedResults<Contact>

    private struct SetupStep: Identifiable {
        let title: String
        let icon: String
        let isDone: Bool
        let destination: AnyView

        var id: String { title }
    }

    private var steps: [SetupStep] {
        [
            SetupStep(title: "Add your name", icon: "person.fill", isDone: !fullName.isEmpty,
                      destination: AnyView(ProfileView())),
            SetupStep(title: "Add an essential medication", icon: "pills.fill", isDone: !essentialMedications.isEmpty,
                      destination: AnyView(MedicationsView(isPushed: true, opensAddSheetOnAppear: true))),
            SetupStep(title: "Add allergies (or \"none\")", icon: "allergens", isDone: !allergies.isEmpty,
                      destination: AnyView(AllergiesView())),
            SetupStep(title: "Add an emergency contact", icon: "phone.fill", isDone: !contacts.isEmpty,
                      destination: AnyView(ContactsView()))
        ]
    }

    var body: some View {
        let completed = steps.filter { $0.isDone }.count

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("Finish Setting Up")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(completed) of \(steps.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(completed), total: Double(steps.count))
                .tint(.orange)

            ForEach(steps) { step in
                NavigationLink(destination: step.destination) {
                    HStack(spacing: 12) {
                        Image(systemName: step.isDone ? "checkmark.circle.fill" : step.icon)
                            .foregroundColor(step.isDone ? .green : .orange)
                            .frame(width: 24)
                        Text(step.title)
                            .font(.subheadline)
                            .foregroundColor(step.isDone ? .secondary : .primary)
                            .strikethrough(step.isDone)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .orange.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationView {
        SetupChecklistView()
            .padding()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
