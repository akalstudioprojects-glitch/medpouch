//
//  NotificationManager.swift
//  MedicalWallet
//
//  Local medication reminders. Everything is scheduled on the device - no push server.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    // "Three times daily" is the most reminders a single medication can have
    private let maxRemindersPerMedication = 3

    private init() {}

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Error requesting notification permission: \(error)")
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func scheduleMedicationReminder(medicationName: String, medicationID: UUID, frequency: String) {
        let times = Self.reminderTimes(for: frequency)
        guard !times.isEmpty else { return }

        // Asks for permission the first time a reminder is needed; returns immediately if already decided
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            for (index, components) in times.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "Medication Reminder"
                content.body = "Time to take \(medicationName)"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: self.identifier(for: medicationID, index: index),
                    content: content,
                    trigger: trigger
                )

                self.center.add(request) { error in
                    if let error {
                        print("Error scheduling reminder: \(error)")
                    }
                }
            }
        }
    }

    func rescheduleMedicationReminder(medicationName: String, medicationID: UUID, frequency: String) {
        cancelMedicationReminder(medicationID: medicationID)
        scheduleMedicationReminder(medicationName: medicationName, medicationID: medicationID, frequency: frequency)
    }

    func cancelMedicationReminder(medicationID: UUID) {
        let identifiers = (0..<maxRemindersPerMedication).map { identifier(for: medicationID, index: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    private func identifier(for medicationID: UUID, index: Int) -> String {
        "medication-\(medicationID.uuidString)-\(index)"
    }

    // MARK: - Reminder schedule

    static func reminderTimes(for frequency: String) -> [DateComponents] {
        func time(_ hour: Int) -> DateComponents {
            DateComponents(hour: hour, minute: 0)
        }

        switch frequency.lowercased() {
        case "daily":
            return [time(9)]
        case "twice daily":
            return [time(9), time(21)]
        case "three times daily":
            return [time(8), time(14), time(20)]
        case "weekly":
            var components = time(9)
            components.weekday = Calendar.current.component(.weekday, from: Date())
            return [components]
        default:
            // "As needed" and "Other" have no fixed schedule
            return []
        }
    }

    // Human-readable summary shown under the frequency picker
    static func reminderDescription(for frequency: String) -> String {
        let times = reminderTimes(for: frequency)
        guard !times.isEmpty else {
            return "No automatic reminders for this frequency."
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let labels = times.compactMap { components -> String? in
            guard let date = Calendar.current.date(
                bySettingHour: components.hour ?? 9,
                minute: components.minute ?? 0,
                second: 0,
                of: Date()
            ) else { return nil }
            return timeFormatter.string(from: date)
        }
        let joined = ListFormatter.localizedString(byJoining: labels)

        if frequency.lowercased() == "weekly" {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            return "Reminder every \(dayFormatter.string(from: Date())) at \(joined)."
        }
        return times.count == 1 ? "Reminder at \(joined)." : "Reminders at \(joined)."
    }
}
