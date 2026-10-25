//
//  MedicalOptions.swift
//  MedicalWallet
//
//  Picker choices and settings keys shared across screens
//

import Foundation

enum MedicalOptions {
    static let bloodTypes = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    static let allergySeverities = ["Mild", "Moderate", "Severe", "Life-threatening"]
    static let relationships = ["Spouse/Partner", "Parent", "Child", "Sibling", "Grandparent", "Friend", "Doctor", "Caregiver", "Other"]
}

enum SettingsKeys {
    // Every @AppStorage key the app uses, so "Delete All Data" can reset them
    static let all = [
        "fullName",
        "dateOfBirth",
        "bloodType",
        "medicalConditions",
        "isOrganDonor",
        "showQRCode",
        "hasCompletedOnboarding",
        "hasDismissedFamilyHint"
    ]
}
