import SwiftUI

struct RegistrationProfileDraft {
    let name: String
    let diet: DietaryPreference
    let allergens: [String]
}

struct ProfileSetupView: View {
    @State private var name: String
    @State private var selectedDiet: DietaryPreference
    @State private var allergenInput = ""
    @State private var allergens: [String]
    @State private var isSaving = false

    let onComplete: (RegistrationProfileDraft) async -> Void
    let onSkip: () -> Void

    init(
        initialName: String,
        initialDiet: DietaryPreference,
        initialAllergens: [String],
        onComplete: @escaping (RegistrationProfileDraft) async -> Void,
        onSkip: @escaping () -> Void
    ) {
        _name = State(initialValue: initialName)
        _selectedDiet = State(initialValue: initialDiet)
        _allergens = State(initialValue: initialAllergens)
        self.onComplete = onComplete
        self.onSkip = onSkip
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header

                VStack(alignment: .leading, spacing: 22) {
                    setupSection("Name") {
                        textField("Name", systemImage: "person", text: $name, contentType: .name)
                    }

                    setupSection("Diet") {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 108), spacing: 8)],
                            alignment: .leading,
                            spacing: 8
                        ) {
                            ForEach(profileDiets) { diet in
                                optionButton(diet.profileSetupTitle, isSelected: selectedDiet == diet) {
                                    withAnimation(DSMotion.snappy) {
                                        selectedDiet = diet
                                    }
                                }
                            }
                        }
                    }

                    setupSection("Allergens") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "cross.case")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(DSColor.accent)
                                    .frame(width: 20)

                                TextField("Add allergen", text: $allergenInput)
                                    .font(DSTypography.body)
                                    .foregroundStyle(DSColor.textPrimary)
                                    .tint(DSColor.accent)
                                    .submitLabel(.done)
                                    .onSubmit(addAllergen)

                                if canAddAllergen {
                                    Button(action: addAllergen) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(DSColor.textPrimary)
                                            .frame(width: 34, height: 34)
                                            .editorialGlass(cornerRadius: 17, interactive: true)
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.leading, 15)
                            .padding(.trailing, 8)
                            .frame(height: 52)
                            .background(DSColor.elevatedCard.opacity(0.72))
                            .clipShape(Capsule())

                            if !allergens.isEmpty {
                                SetupChipGrid(values: allergens) { allergen in
                                    withAnimation(DSMotion.list) {
                                        allergens.removeAll { $0 == allergen }
                                    }
                                }
                                .transition(.opacity.combined(with: .offset(y: -8)))
                            }
                        }
                    }
                }

                VStack(spacing: 10) {
                    PrimaryButton("Save Profile", systemImage: "checkmark", isLoading: isSaving) {
                        save()
                    }

                    Button(action: onSkip) {
                        Text("Skip")
                            .font(DSTypography.body.weight(.semibold))
                            .foregroundStyle(DSColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                    .dsPressable(scale: 0.97)
                    .disabled(isSaving)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 34)
        }
        .appBackground()
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("PUMP KITCHEN")
                .font(DSTypography.micro)
                .foregroundStyle(DSColor.accent)
                .tracking(1.3)

            Text("Set up your profile")
                .font(.system(size: 31, weight: .semibold, design: .serif))
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("These details help tune recipes to your diet and allergies.")
                .font(DSTypography.body)
                .foregroundStyle(DSColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var profileDiets: [DietaryPreference] {
        [.regular, .vegetarian, .vegan]
    }

    private var canAddAllergen: Bool {
        !allergenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        Task {
            isSaving = true
            await onComplete(
                RegistrationProfileDraft(
                    name: name,
                    diet: selectedDiet,
                    allergens: allergens
                )
            )
            isSaving = false
        }
    }

    private func addAllergen() {
        let allergen = allergenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !allergen.isEmpty else { return }
        guard !allergens.contains(where: { $0.caseInsensitiveCompare(allergen) == .orderedSame }) else {
            allergenInput = ""
            return
        }

        withAnimation(DSMotion.list) {
            allergens.append(allergen)
            allergenInput = ""
        }
    }

    private func setupSection<Content: View>(
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

    private func textField(
        _ placeholder: String,
        systemImage: String,
        text: Binding<String>,
        contentType: UITextContentType
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DSColor.accent)
                .frame(width: 20)

            TextField(LocalizedStringKey(placeholder), text: text)
                .font(DSTypography.body)
                .textContentType(contentType)
                .foregroundStyle(DSColor.textPrimary)
                .tint(DSColor.accent)
        }
        .padding(.horizontal, 15)
        .frame(height: 52)
        .background(DSColor.elevatedCard.opacity(0.72))
        .clipShape(Capsule())
    }

    private func optionButton(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(DSTypography.caption)
                .foregroundStyle(isSelected ? DSColor.accent : DSColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 13)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? DSColor.accentSurface : DSColor.elevatedCard)
                .clipShape(Capsule())
                .overlay {
                    if isSelected {
                        Capsule()
                            .stroke(DSColor.accent.opacity(0.3), lineWidth: 0.75)
                    }
                }
        }
        .buttonStyle(.plain)
        .dsPressable(scale: 0.95)
    }
}

private struct SetupChipGrid: View {
    let values: [String]
    let onRemove: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Button {
                        onRemove(value)
                    } label: {
                        HStack(spacing: 7) {
                            Text(value)
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.textPrimary)
                        .padding(.horizontal, 13)
                        .frame(height: 38)
                        .background(DSColor.elevatedCard)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .dsPressable(scale: 0.96)
                }
            }
        }
    }
}

private extension DietaryPreference {
    var profileSetupTitle: String {
        switch self {
        case .regular: "Standard Diet"
        case .healthy: "Standard Diet"
        case .vegetarian: "Vegetarianism"
        case .vegan: "Veganism"
        case .lactoseFree: "Standard Diet"
        case .glutenFree: "Standard Diet"
        }
    }
}
