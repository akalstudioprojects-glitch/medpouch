//
//  Persistence.swift
//  MedicalWallet
//
//  Core Data stack. All data is stored only on this device - there is no backend.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = "Lisinopril"
        medication.dosage = "10mg"
        medication.frequency = "Daily"
        medication.isEssential = true
        medication.dateAdded = Date()

        let prescription = Prescription(context: context)
        prescription.id = UUID()
        prescription.medicationName = "Amoxicillin"
        prescription.dosage = "500mg"
        prescription.doctorName = "Dr. Patel"
        prescription.dateIssued = Date()
        prescription.dateAdded = Date()

        let allergy = Allergy(context: context)
        allergy.id = UUID()
        allergy.allergen = "Penicillin"
        allergy.severity = "Severe"
        allergy.reaction = "Hives, swelling"
        allergy.dateAdded = Date()

        let contact = Contact(context: context)
        contact.id = UUID()
        contact.name = "Sam Taylor"
        contact.relationship = "Spouse/Partner"
        contact.phoneNumber = "+1 555 123 4567"
        contact.dateAdded = Date()

        do {
            try context.save()
        } catch {
            print("Error creating preview data: \(error)")
        }
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MedPouch")

        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                // Keep the health data encrypted on disk while the device is locked
                description.setOption(FileProtectionType.completeUnlessOpen as NSObject,
                                      forKey: NSPersistentStoreFileProtectionKey)
            }
            // Lets future versions of the data model upgrade existing data instead of crashing
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
