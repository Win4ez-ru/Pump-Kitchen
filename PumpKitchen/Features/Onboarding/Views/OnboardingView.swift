import SwiftUI

struct OnboardingView: View {
    @State private var selectedGoal: FitnessGoal
    @State private var heightCentimeters: Double
    @State private var weightKilograms: Double
    @State private var activityLevel: ActivityLevel

    let onComplete: (FitnessGoal, Double, Double, ActivityLevel) -> Void

    init(
        initialGoal: FitnessGoal,
        initialHeightCentimeters: Double,
        initialWeightKilograms: Double,
        initialActivityLevel: ActivityLevel,
        onComplete: @escaping (FitnessGoal, Double, Double, ActivityLevel) -> Void
    ) {
        _selectedGoal = State(initialValue: initialGoal)
        _heightCentimeters = State(initialValue: initialHeightCentimeters)
        _weightKilograms = State(initialValue: initialWeightKilograms)
        _activityLevel = State(initialValue: initialActivityLevel)
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            DSColor.ricePaper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Pump Kitchen")
                            .font(DSTypography.largeTitle)
                            .foregroundStyle(DSColor.graphite)
                        Text("Tell us the basics once. Recipes will adapt to your body, activity, and goal.")
                            .font(DSTypography.body)
                            .foregroundStyle(DSColor.inkMuted)
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                Text("Goal")
                                    .font(DSTypography.headline)
                                Picker("Goal", selection: $selectedGoal) {
                                    ForEach(FitnessGoal.allCases) { goal in
                                        Text(goal.title).tag(goal)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            metricSlider(title: "Height", value: $heightCentimeters, range: 130...220, suffix: "cm")
                            metricSlider(title: "Weight", value: $weightKilograms, range: 40...160, suffix: "kg")

                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                Text("Activity")
                                    .font(DSTypography.headline)
                                Picker("Activity", selection: $activityLevel) {
                                    ForEach(ActivityLevel.allCases) { level in
                                        Text(level.title).tag(level)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            PrimaryButton("Start Cooking", systemImage: "checkmark") {
                                onComplete(selectedGoal, heightCentimeters, weightKilograms, activityLevel)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        OnboardingBenefit(icon: "person.crop.circle.fill", title: "Personal profile", subtitle: "Your goal and activity guide recipe suggestions.")
                        OnboardingBenefit(icon: "scalemass.fill", title: "Flexible portions", subtitle: "Add ingredient amounts in Home. The backend can scale the rest.")
                        OnboardingBenefit(icon: "arrow.triangle.2.circlepath", title: "Ingredient swaps", subtitle: "Recipe details include substitute ideas when something is missing.")
                    }
                }
                .padding(DSSpacing.lg)
            }
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
                    .font(DSTypography.headline)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(suffix)")
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColor.matcha)
            }

            Slider(value: value, in: range, step: 1)
                .tint(DSColor.matcha)
        }
    }
}

private struct OnboardingBenefit: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: DSSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(DSColor.matcha)
                .frame(width: 30, height: 30)
                .background(DSColor.matcha.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSTypography.headline)
                Text(subtitle)
                    .font(DSTypography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DSSpacing.md)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
