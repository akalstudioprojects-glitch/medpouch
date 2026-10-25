//
//  HomeView.swift
//  MedicalWallet
//
//  Main dashboard/home screen
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("fullName") private var fullName = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Prescription.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "familyMemberID == nil"),
        animation: .default)
    private var prescriptions: FetchedResults<Prescription>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Medication.name, ascending: true)],
        predicate: NSPredicate(format: "isEssential == YES AND familyMemberID == nil"),
        animation: .default)
    private var essentialMedications: FetchedResults<Medication>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Allergy.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "familyMemberID == nil"),
        animation: .default)
    private var allergies: FetchedResults<Allergy>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)],
        predicate: NSPredicate(format: "familyMemberID == nil"),
        animation: .default)
    private var contacts: FetchedResults<Contact>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FamilyMember.dateAdded, ascending: false)],
        animation: .default)
    private var familyMembers: FetchedResults<FamilyMember>

    @AppStorage("hasDismissedFamilyHint") private var hasDismissedFamilyHint = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    HeaderSection()

                    // Family Member Hint (show if no family members added and not dismissed)
                    if familyMembers.isEmpty && !hasDismissedFamilyHint {
                        FamilyMemberHintCard(onDismiss: {
                            hasDismissedFamilyHint = true
                        })
                    }

                    // Setup Checklist (show if not complete)
                    if hasCompletedOnboarding && !isSetupComplete {
                        SetupChecklistView()
                    }

                    // Quick Stats
                    QuickStatsSection(
                        totalPrescriptions: prescriptions.count,
                        essentialMeds: essentialMedications.count
                    )

                    // Quick Actions
                    QuickActionsView()

                    // Recent Prescriptions
                    if !prescriptions.isEmpty {
                        RecentPrescriptionsSection(prescriptions: Array(prescriptions.prefix(3)))
                    } else {
                        EmptyStateCard()
                    }
                }
                .padding()
            }
            .navigationTitle("MedPouch")
            .background(Color(.systemGroupedBackground))
        }
    }

    var isSetupComplete: Bool {
        !fullName.isEmpty && !essentialMedications.isEmpty && !allergies.isEmpty && !contacts.isEmpty
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),
                    Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.pink, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Welcome Back!")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "cross.case.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Your health companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quick Stats Section
struct QuickStatsSection: View {
    let totalPrescriptions: Int
    let essentialMeds: Int

    var body: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Prescriptions",
                value: "\(totalPrescriptions)",
                icon: "doc.text.fill",
                color: .blue
            )

            StatCard(
                title: "Essential Meds",
                value: "\(essentialMeds)",
                icon: "pills.fill",
                color: .green
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Recent Prescriptions Section
struct RecentPrescriptionsSection: View {
    let prescriptions: [Prescription]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: PrescriptionsView()) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("Recent Prescriptions")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(prescriptions) { prescription in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "pills.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(prescription.medicationName ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 4) {
                            Image(systemName: "stethoscope")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(prescription.doctorName ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let date = prescription.dateAdded {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.05),
                            Color.purple.opacity(0.05)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quick Actions View
struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.headline)
                    .foregroundColor(.yellow)
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add\nPrescription",
                    color: .blue,
                    destination: AnyView(PrescriptionsView(opensAddSheetOnAppear: true))
                )

                QuickActionButton(
                    icon: "pills.circle.fill",
                    title: "Add\nMedication",
                    color: .green,
                    destination: AnyView(MedicationsView(isPushed: true, opensAddSheetOnAppear: true))
                )

                QuickActionButton(
                    icon: "globe.americas.fill",
                    title: "Travel\nMeds",
                    color: .cyan,
                    destination: AnyView(TravelMedsView())
                )

                QuickActionButton(
                    icon: "qrcode",
                    title: "Emergency\nCard",
                    color: .red,
                    destination: AnyView(WalletCardView())
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 35))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No Prescriptions Yet")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Add your first prescription to keep it with you wherever you go")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                Image(systemName: "arrow.up")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("Use Quick Actions above to get started")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Family Member Hint Card
struct FamilyMemberHintCard: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.pink]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: "person.3.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Track Family Members Too!")
                                .font(.headline)
                                .fontWeight(.bold)

                            Text("Did you know?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("You can manage medical information for your entire family! Add medications, allergies, and emergency contacts for each family member.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    NavigationLink(destination: FamilyMembersView()) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Family Member")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
