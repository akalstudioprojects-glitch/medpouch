//
//  OnboardingView.swift
//  MedicalWallet
//
//  First-launch welcome, profile basics, reminder permission, and medical disclaimer
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("fullName") private var fullName = ""
    @AppStorage("bloodType") private var bloodType = "Unknown"

    @State private var step = 0
    @State private var hasAcceptedDisclaimer = false

    private let stepCount = 4

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            TabView(selection: $step) {
                welcomePage.tag(0)
                profilePage.tag(1)
                remindersPage.tag(2)
                disclaimerPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Pages

    private var welcomePage: some View {
        OnboardingPage(
            icon: "heart.text.square.fill",
            colors: [.pink, .orange],
            title: "Welcome to MedPouch",
            subtitle: "Your medications, prescriptions, allergies, and emergency details, always in your pocket.",
            buttonTitle: "Get Started",
            action: { step = 1 }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                OnboardingFeatureRow(icon: "pills.fill", color: .green, text: "Track medications and get reminders")
                OnboardingFeatureRow(icon: "doc.text.fill", color: .blue, text: "Keep photos of your prescriptions")
                OnboardingFeatureRow(icon: "staroflife.fill", color: .red, text: "Show an emergency card with a QR code")
                OnboardingFeatureRow(icon: "person.3.fill", color: .purple, text: "Manage records for your whole family")
            }
        }
    }

    private var profilePage: some View {
        OnboardingPage(
            icon: "person.crop.circle.fill",
            colors: [.blue, .purple],
            title: "About You",
            subtitle: "This appears on your emergency card. You can change it any time in Profile.",
            buttonTitle: "Continue",
            action: { step = 2 }
        ) {
            VStack(spacing: 12) {
                TextField("Full Name", text: $fullName)
                    .textContentType(.name)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                HStack {
                    Label("Blood Type", systemImage: "drop.fill")
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(MedicalOptions.bloodTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }

    private var remindersPage: some View {
        OnboardingPage(
            icon: "bell.badge.fill",
            colors: [.orange, .yellow],
            title: "Medication Reminders",
            subtitle: "MedPouch can remind you when it's time to take your medications. Reminders are scheduled on your iPhone, with nothing sent to a server.",
            buttonTitle: "Turn On Reminders",
            action: {
                NotificationManager.shared.requestAuthorization { _ in
                    step = 3
                }
            }
        ) {
            Button("Not Now") {
                step = 3
            }
            .foregroundColor(.secondary)
        }
    }

    private var disclaimerPage: some View {
        OnboardingPage(
            icon: "lock.shield.fill",
            colors: [.green, .teal],
            title: "Private & Secure",
            subtitle: "Your information is stored only on this iPhone. MedPouch has no accounts and no servers, and never sends your health data anywhere.",
            buttonTitle: "Start Using MedPouch",
            isButtonEnabled: hasAcceptedDisclaimer,
            action: { hasCompletedOnboarding = true }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("MedPouch helps you organize your own medical information. It does not provide medical advice, diagnosis, or treatment. Always follow the guidance of your doctor or pharmacist, and in an emergency contact your local emergency services.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Toggle(isOn: $hasAcceptedDisclaimer) {
                    Text("I understand")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Page Layout
struct OnboardingPage<Content: View>: View {
    let icon: String
    let colors: [Color]
    let title: String
    let subtitle: String
    let buttonTitle: String
    var isButtonEnabled = true
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: colors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)

                        Image(systemName: icon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 12) {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    content()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Button(action: action) {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isButtonEnabled ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(!isButtonEnabled)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
