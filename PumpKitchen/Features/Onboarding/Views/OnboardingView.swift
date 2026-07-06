import SwiftUI

struct OnboardingView: View {
    @State private var selectedGoal: FitnessGoal
    @State private var heightCentimeters: Double
    @State private var weightKilograms: Double
    @State private var activityLevel: ActivityLevel
    @State private var dietaryPreference: DietaryPreference

    let onComplete: (FitnessGoal, Double, Double, ActivityLevel, DietaryPreference) -> Void

    init(
        initialGoal: FitnessGoal,
        initialHeightCentimeters: Double,
        initialWeightKilograms: Double,
        initialActivityLevel: ActivityLevel,
        initialDietaryPreference: DietaryPreference,
        onComplete: @escaping (FitnessGoal, Double, Double, ActivityLevel, DietaryPreference) -> Void
    ) {
        _selectedGoal = State(initialValue: initialGoal)
        _heightCentimeters = State(initialValue: initialHeightCentimeters)
        _weightKilograms = State(initialValue: initialWeightKilograms)
        _activityLevel = State(initialValue: initialActivityLevel)
        _dietaryPreference = State(initialValue: initialDietaryPreference)
        self.onComplete = onComplete
    }

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    onboardingHero
                        .frame(width: max(viewport.size.width - 36, 0))
                        .dsAppear(delay: 0.02)

                    VStack(alignment: .leading, spacing: 24) {
                        optionSection("Goal") {
                            DSSegmentedControl(
                                options: [
                                    (.fatLoss, "Cut"),
                                    (.maintenance, "Maintain"),
                                    (.muscleGain, "Bulk")
                                ],
                                selection: $selectedGoal
                            )
                        }

                        metricSlider(
                            title: "Height",
                            value: $heightCentimeters,
                            range: 130...220,
                            suffix: "cm"
                        )

                        metricSlider(
                            title: "Weight",
                            value: $weightKilograms,
                            range: 40...160,
                            suffix: "kg"
                        )

                        optionSection("Diet") {
                            Menu {
                                ForEach(onboardingDiets) { diet in
                                    Button {
                                        withAnimation(DSMotion.snappy) {
                                            dietaryPreference = diet
                                        }
                                    } label: {
                                        Text(LocalizedStringKey(diet.title))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(dietaryPreference.title))
                                        .font(DSTypography.body.weight(.semibold))
                                        .foregroundStyle(DSColor.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(DSColor.accent)
                                }
                                .padding(.horizontal, 15)
                                .frame(height: 48)
                                .background(DSColor.elevatedCard)
                                .clipShape(Capsule())
                            }
                        }

                        optionSection("Activity") {
                            DSSegmentedControl(
                                options: ActivityLevel.allCases.map { ($0, $0.title) },
                                selection: $activityLevel
                            )
                        }

                        PrimaryButton("Start Cooking", systemImage: "checkmark") {
                            withAnimation(DSMotion.gentle) {
                                onComplete(
                                    selectedGoal,
                                    heightCentimeters,
                                    weightKilograms,
                                    activityLevel,
                                    dietaryPreference
                                )
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(width: max(viewport.size.width - 36, 0), alignment: .leading)
                    .dsAppear(delay: 0.14)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, max(30, viewport.safeAreaInsets.bottom + 18))
            }
            .appBackground()
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var onboardingDiets: [DietaryPreference] {
        [.regular, .vegetarian, .vegan]
    }

    private var onboardingHero: some View {
        ZStack(alignment: .bottomLeading) {
            RecipeImageView(
                url: URL(string: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=1600")
            )

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.24),
                    .init(color: .black.opacity(0.2), location: 0.58),
                    .init(color: .black.opacity(0.82), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                Text("PUMP KITCHEN")
                    .font(DSTypography.micro)
                    .foregroundStyle(DSColor.accent)
                    .tracking(1.3)

                Text("Your kitchen, your rhythm")
                    .font(.system(size: 31, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(18)
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 22, x: 0, y: 14)
    }

    private func optionSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(DSColor.textPrimary)

            content()
        }
    }

    private func metricSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(DSColor.textPrimary)
                Spacer()
                (Text("\(Int(value.wrappedValue)) ")
                    + Text(LocalizedStringKey(suffix)))
                    .font(DSTypography.caption.weight(.semibold))
                    .foregroundStyle(DSColor.accent)
                    .contentTransition(.numericText())
            }

            Slider(value: value, in: range, step: 1)
                .tint(DSColor.accent)
        }
    }
}
