//
//  TravelMedsView.swift
//  MedicalWallet
//
//  Packing list for travelling with medications
//

import SwiftUI
import CoreData

struct TravelMedsView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Medication.isEssential, ascending: false),
            NSSortDescriptor(keyPath: \Medication.name, ascending: true)
        ],
        predicate: NSPredicate(format: "familyMemberID == nil"),
        animation: .default)
    private var medications: FetchedResults<Medication>

    @State private var tripDays = 7
    @State private var packedIDs: Set<NSManagedObjectID> = []

    // Extra days of supply in case of travel delays
    private let spareDays = 3

    var body: some View {
        List {
            Section {
                Stepper("Trip Length: \(tripDays) day\(tripDays == 1 ? "" : "s")", value: $tripDays, in: 1...180)
            } header: {
                Label("Your Trip", systemImage: "airplane")
            } footer: {
                Text("Quantities are estimates based on each medication's frequency, plus \(spareDays) spare days in case of delays. Check with your pharmacist for longer trips.")
                    .font(.caption)
            }

            Section {
                if medications.isEmpty {
                    NavigationLink(destination: MedicationsView(isPushed: true, opensAddSheetOnAppear: true)) {
                        Label("Add medications to build your packing list", systemImage: "plus.circle")
                    }
                } else {
                    ForEach(medications) { medication in
                        Button {
                            togglePacked(medication)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: packedIDs.contains(medication.objectID) ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(packedIDs.contains(medication.objectID) ? .green : .secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(medication.name ?? "Unknown")
                                            .font(.headline)
                                            .strikethrough(packedIDs.contains(medication.objectID))
                                        if medication.isEssential {
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    Text(quantityText(for: medication))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Label("Packing List (\(packedIDs.count)/\(medications.count) packed)", systemImage: "suitcase.fill")
            }

            Section {
                TravelTipRow(icon: "bag.fill", text: "Keep medications in your carry-on bag, in their original labelled containers.")
                TravelTipRow(icon: "doc.text.fill", text: "Bring copies of your prescriptions. Photos saved in Prescriptions work well.")
                TravelTipRow(icon: "globe", text: "Check your destination's rules. Some medications are restricted or need a doctor's letter.")
                TravelTipRow(icon: "clock.fill", text: "Reminders follow your iPhone's local time, so they adjust when you change time zones.")
                TravelTipRow(icon: "staroflife.fill", text: "Make sure your emergency card is up to date before you leave.")
            } header: {
                Label("Travel Tips", systemImage: "lightbulb.fill")
            }
        }
        .navigationTitle("Travel Meds")
        .toolbar {
            if !medications.isEmpty {
                ShareLink(item: packingListText) {
                    Label("Share List", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private func togglePacked(_ medication: Medication) {
        if packedIDs.contains(medication.objectID) {
            packedIDs.remove(medication.objectID)
        } else {
            packedIDs.insert(medication.objectID)
        }
    }

    private func dosesNeeded(for medication: Medication) -> Int? {
        let days = tripDays + spareDays
        switch medication.frequency?.lowercased() {
        case "daily": return days
        case "twice daily": return days * 2
        case "three times daily": return days * 3
        case "weekly": return Int((Double(days) / 7).rounded(.up))
        default: return nil
        }
    }

    private func quantityText(for medication: Medication) -> String {
        let dosage = medication.dosage.map { "\($0) · " } ?? ""
        if let doses = dosesNeeded(for: medication) {
            return "\(dosage)Pack about \(doses) dose\(doses == 1 ? "" : "s")"
        }
        return "\(dosage)Taken as needed. Pack a spare supply"
    }

    private var packingListText: String {
        let lines = medications.map { "• \($0.name ?? "Unknown"): \(quantityText(for: $0))" }
        return (["Medication packing list for a \(tripDays)-day trip:"] + lines).joined(separator: "\n")
    }
}

struct TravelTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        TravelMedsView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
