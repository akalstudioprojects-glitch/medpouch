//
//  WalletCardView.swift
//  MedicalWallet
//
//  Emergency medical card with QR code, for the user or a family member
//

import SwiftUI
import CoreData

struct WalletCardView: View {
    @Environment(\.displayScale) private var displayScale

    @AppStorage("fullName") private var fullName = ""
    @AppStorage("dateOfBirth") private var dateOfBirth: Double = 0 // 0 = not set
    @AppStorage("bloodType") private var bloodType = "Unknown"
    @AppStorage("medicalConditions") private var medicalConditions = ""
    @AppStorage("isOrganDonor") private var isOrganDonor = false
    @AppStorage("showQRCode") private var showQRCode = true

    @FetchRequest private var allergies: FetchedResults<Allergy>
    @FetchRequest private var medications: FetchedResults<Medication>
    @FetchRequest private var contacts: FetchedResults<Contact>

    // nil = the user's own card
    let member: FamilyMember?

    init(member: FamilyMember? = nil) {
        self.member = member
        // A member without an ID gets a throwaway one so their card never shows the user's records
        let ownerID: UUID? = member.map { $0.id ?? UUID() }

        _allergies = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Allergy.dateAdded, ascending: true)],
            predicate: NSPredicate.owned(by: ownerID))
        _medications = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Medication.name, ascending: true)],
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate.owned(by: ownerID),
                NSPredicate(format: "isEssential == YES")
            ]))
        _contacts = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)],
            predicate: NSPredicate.owned(by: ownerID))
    }

    var body: some View {
        let info = cardInfo
        let qrImage = showQRCode ? QRCodeGenerator.image(from: info.qrText) : nil

        ScrollView {
            VStack(spacing: 20) {
                EmergencyCardContent(info: info, qrImage: qrImage)

                if info.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(member == nil
                             ? "Your card is empty. Add your details in Profile, plus medications, allergies, and emergency contacts."
                             : "This card is empty. Add details, medications, allergies, and contacts for this family member.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $showQRCode) {
                        Label("Show QR Code", systemImage: "qrcode")
                    }
                    Text("Anyone who scans the QR code can read the information on this card.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                if let image = renderedCard(info: info, qrImage: qrImage) {
                    ShareLink(item: image, preview: SharePreview("Emergency Card", image: image)) {
                        Label("Share or Save Card Image", systemImage: "square.and.arrow.up")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }

                if member == nil {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.iphone")
                            .font(.title2)
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tip: Set Up Medical ID")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Also add your details to Medical ID in Apple's Health app. First responders can see it from your Lock Screen without unlocking your iPhone.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(member == nil ? "Emergency Card" : "\(member?.name ?? "Family Member")'s Card")
    }

    private var cardInfo: EmergencyCardInfo {
        let allergyLines = allergies.compactMap { allergy -> String? in
            guard let allergen = allergy.allergen else { return nil }
            if let severity = allergy.severity {
                return "\(allergen) (\(severity))"
            }
            return allergen
        }
        let medicationLines = medications.compactMap { medication -> String? in
            guard let name = medication.name else { return nil }
            return [name, medication.dosage, medication.frequency].compactMap { $0 }.joined(separator: " · ")
        }
        let contactLines = contacts.compactMap { contact -> String? in
            guard let name = contact.name else { return nil }
            let relationship = contact.relationship.map { " (\($0))" } ?? ""
            let phone = contact.phoneNumber.map { ": \($0)" } ?? ""
            return name + relationship + phone
        }

        if let member {
            return EmergencyCardInfo(
                name: member.name ?? "",
                dateOfBirth: member.dateOfBirth,
                bloodType: member.bloodType == "Unknown" ? nil : member.bloodType,
                conditions: member.medicalConditions,
                isOrganDonor: false,
                allergies: allergyLines,
                medications: medicationLines,
                contacts: contactLines
            )
        }

        return EmergencyCardInfo(
            name: fullName,
            dateOfBirth: dateOfBirth == 0 ? nil : Date(timeIntervalSince1970: dateOfBirth),
            bloodType: bloodType == "Unknown" ? nil : bloodType,
            conditions: medicalConditions.nilIfBlank,
            isOrganDonor: isOrganDonor,
            allergies: allergyLines,
            medications: medicationLines,
            contacts: contactLines
        )
    }

    @MainActor
    private func renderedCard(info: EmergencyCardInfo, qrImage: UIImage?) -> Image? {
        let renderer = ImageRenderer(
            content: EmergencyCardContent(info: info, qrImage: qrImage)
                .frame(width: 360)
                .padding(12)
        )
        renderer.scale = displayScale
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

// MARK: - Card Data
struct EmergencyCardInfo {
    var name: String
    var dateOfBirth: Date?
    var bloodType: String?
    var conditions: String?
    var isOrganDonor: Bool
    var allergies: [String]
    var medications: [String]
    var contacts: [String]

    var isEmpty: Bool {
        name.isEmpty && allergies.isEmpty && medications.isEmpty && contacts.isEmpty
    }

    // Plain text so any phone camera can read it without installing an app
    var qrText: String {
        var lines = ["EMERGENCY MEDICAL INFO"]
        lines.append("Name: \(name.isEmpty ? "Not set" : name)")
        if let dateOfBirth {
            lines.append("DOB: \(dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
        }
        if let bloodType {
            lines.append("Blood type: \(bloodType)")
        }
        lines.append("Allergies: \(allergies.isEmpty ? "None listed" : allergies.joined(separator: "; "))")
        if !medications.isEmpty {
            lines.append("Medications: \(medications.joined(separator: "; "))")
        }
        if let conditions {
            lines.append("Conditions: \(conditions)")
        }
        if isOrganDonor {
            lines.append("Organ donor: Yes")
        }
        if !contacts.isEmpty {
            lines.append("Emergency contacts: \(contacts.joined(separator: "; "))")
        }
        // Keeps the QR code dense enough to scan reliably
        return String(lines.joined(separator: "\n").prefix(1500))
    }
}

// MARK: - Card Design
struct EmergencyCardContent: View {
    let info: EmergencyCardInfo
    let qrImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "staroflife.fill")
                    .font(.title2)
                Text("EMERGENCY MEDICAL CARD")
                    .font(.headline)
                    .fontWeight(.heavy)
                Spacer()
            }
            .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(info.name.isEmpty ? "Name not set" : info.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    if let dateOfBirth = info.dateOfBirth {
                        Text("DOB \(dateOfBirth.formatted(date: .abbreviated, time: .omitted))")
                    }
                    if let bloodType = info.bloodType {
                        Text("Blood \(bloodType)")
                    }
                    if info.isOrganDonor {
                        Text("Organ Donor")
                    }
                }
                .font(.caption)
                .fontWeight(.semibold)
            }
            .foregroundColor(.white)

            EmergencyCardSection(title: "Allergies", items: info.allergies)
            EmergencyCardSection(title: "Medications", items: info.medications)
            if let conditions = info.conditions {
                EmergencyCardSection(title: "Conditions", items: [conditions])
            }
            EmergencyCardSection(title: "Emergency Contacts", items: info.contacts)

            if let qrImage {
                HStack {
                    Spacer()
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.red, Color(red: 0.75, green: 0.1, blue: 0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct EmergencyCardSection: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.75))

            if items.isEmpty {
                Text("None listed")
                    .font(.subheadline)
                    .foregroundColor(.white)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Text("• \(item)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        WalletCardView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
