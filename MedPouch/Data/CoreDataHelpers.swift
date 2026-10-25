//
//  CoreDataHelpers.swift
//  MedicalWallet
//
//  Shared helpers for querying and deleting records
//

import CoreData

extension NSPredicate {
    // Records with a nil familyMemberID belong to the user; otherwise they belong to that family member
    static func owned(by familyMemberID: UUID?) -> NSPredicate {
        if let familyMemberID {
            return NSPredicate(format: "familyMemberID == %@", familyMemberID as NSUUID)
        }
        return NSPredicate(format: "familyMemberID == nil")
    }
}

extension NSManagedObjectContext {
    // Deletes a family member together with all of their records and medication reminders
    func deleteFamilyMember(_ member: FamilyMember) throws {
        var medicationIDs: [UUID] = []

        if let memberID = member.id {
            let predicate = NSPredicate.owned(by: memberID)

            let medicationRequest: NSFetchRequest<Medication> = Medication.fetchRequest()
            medicationRequest.predicate = predicate
            let medications = try fetch(medicationRequest)
            medicationIDs = medications.compactMap { $0.id }
            medications.forEach { delete($0) }

            let otherRequests: [NSFetchRequest<NSFetchRequestResult>] = [
                Prescription.fetchRequest(),
                Allergy.fetchRequest(),
                Contact.fetchRequest()
            ]
            for request in otherRequests {
                request.predicate = predicate
                let objects = try fetch(request) as? [NSManagedObject] ?? []
                objects.forEach { delete($0) }
            }
        }

        delete(member)
        try save()

        medicationIDs.forEach { NotificationManager.shared.cancelMedicationReminder(medicationID: $0) }
    }
}

extension String {
    // Trimmed text, or nil when the field was left blank
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
