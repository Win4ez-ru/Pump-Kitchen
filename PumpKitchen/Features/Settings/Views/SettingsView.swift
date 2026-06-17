import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(container: AppContainer) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(settingsStore: container.settingsStore, authSession: container.authSession, profileService: container.profileService)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Label(viewModel.authSession.isAuthenticated ? "Connected to backend" : "Mock session", systemImage: viewModel.authSession.isAuthenticated ? "checkmark.shield.fill" : "wand.and.sparkles")
                        .foregroundStyle(viewModel.authSession.isAuthenticated ? DSColor.matcha : DSColor.yuzu)

                    if viewModel.authSession.isAuthenticated {
                        Button("Log Out", role: .destructive) { viewModel.authSession.logout() }
                    }
                }

                Section("Appearance") {
                    Toggle("Use System Theme", isOn: $viewModel.useSystemTheme)
                }

                Section("Profile") {
                    Picker("Goal", selection: $viewModel.defaultGoal) {
                        ForEach(FitnessGoal.allCases) { goal in
                            Text(goal.title).tag(goal)
                        }
                    }

                    Picker("Activity", selection: $viewModel.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }

                    Picker("Diet", selection: $viewModel.dietaryPreference) {
                        ForEach(DietaryPreference.allCases) { diet in
                            Text(diet.title).tag(diet)
                        }
                    }

                    metricSlider(title: "Height", value: $viewModel.heightCentimeters, range: 130...220, suffix: "cm")
                    metricSlider(title: "Weight", value: $viewModel.weightKilograms, range: 40...160, suffix: "kg")
                }

                Section("Backend") {
                    Toggle("Use Mock Backend", isOn: $viewModel.useMockGeneration)
                        .tint(DSColor.matcha)

                    TextField("https://api.yourdomain.com", text: $viewModel.backendBaseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    Label(
                        viewModel.isUsingMock ? "Mock generation active" : "Backend generation active",
                        systemImage: viewModel.isUsingMock ? "wand.and.sparkles" : "server.rack"
                    )
                    .foregroundStyle(viewModel.isUsingMock ? DSColor.yuzu : DSColor.matcha)

                    Text("Mock mode keeps the full app usable before the real backend is ready. The backend owns the AI provider key and calculates personalized recipe targets from this profile.")
                        .font(DSTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Save Profile") {
                        Task { await viewModel.save() }
                    }
                }

                if let statusMessage = viewModel.statusMessage {
                    Section {
                        Text(statusMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .scrollContentBackground(.hidden)
            .appBackground()
        }
    }


    private func metricSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(suffix)")
                    .foregroundStyle(DSColor.matcha)
            }

            Slider(value: value, in: range, step: 1)
                .tint(DSColor.matcha)
        }
    }
}
