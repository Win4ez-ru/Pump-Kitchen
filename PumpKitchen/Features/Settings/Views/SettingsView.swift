import SwiftUI

struct SettingsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: SettingsViewModel
    @State private var allergenInput = ""

    init(container: AppContainer) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                settingsStore: container.settingsStore,
                authSession: container.authSession,
                profileService: container.profileService
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    profileHero
                        .dsAppear(delay: 0.02, distance: 14)

                    VStack(spacing: 0) {
                        editableNameRow
                        divider
                        dietRow
                        divider
                        allergensRow
                        divider
                        appearanceRow
                        divider
                        languageRow
                    }
                    .dsAppear(delay: 0.1, distance: 16)

                    accountSection
                        .dsAppear(delay: 0.13, distance: 16)

                    #if DEBUG
                    developerConnectionSection
                        .dsAppear(delay: 0.14, distance: 16)
                    #endif

                    Button {
                        Task { await viewModel.save() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                            Text("Save Profile")
                        }
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(DSColor.accent)
                    }
                    .buttonStyle(.plain)
                    .dsPressable(scale: 0.96)

                    if let statusMessage = viewModel.statusMessage {
                        Text(LocalizedStringKey(statusMessage))
                            .font(DSTypography.caption)
                            .foregroundStyle(DSColor.textSecondary)
                    }

                    VStack(spacing: 0) {
                        aboutRow("About", value: "Pump Kitchen")
                        divider
                        aboutRow("Version", value: appVersion)
                        divider
                        privacyPolicyRow
                    }
                    .dsAppear(delay: 0.16, distance: 16)
                }
                .padding(.leading, 44)
                .padding(.trailing, 20)
                .padding(.top, 24)
                .padding(.bottom, 132)
                .containerRelativeFrame(.horizontal) { length, _ in
                    min(length, 680)
                }
            }
            .appBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var accountSection: some View {
        settingSection("Account") {
            HStack(spacing: 12) {
                Image(systemName: authStateIcon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(viewModel.useMockGeneration ? DSColor.accent : DSColor.textSecondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Auth State")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(DSColor.textPrimary)
                    Text(LocalizedStringKey(viewModel.authStateTitle))
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button {
                    withAnimation(DSMotion.gentle) {
                        viewModel.logout()
                    }
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DSColor.destructive)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log Out")
            }
        }
    }

    private var developerConnectionSection: some View {
        settingSection("Developer") {
            VStack(alignment: .leading, spacing: 14) {
                profileTextField(
                    "Backend URL",
                    systemImage: "link",
                    text: $viewModel.backendBaseURL,
                    contentType: .URL
                )
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                segmentedOptions(
                    [
                        ("backend", "Use Backend"),
                        ("mock", "Use Mock Backend")
                    ],
                    selectedID: viewModel.connectionModeID
                ) { modeID in
                    withAnimation(DSMotion.snappy) {
                        viewModel.connectionModeID = modeID
                    }
                }
            }
        }
    }

    private var authStateIcon: String {
        if viewModel.useMockGeneration {
            return "sparkles"
        }

        return viewModel.authSession.isAuthenticated ? "checkmark.seal" : "person.crop.circle.badge.xmark"
    }

    private var profileHero: some View {
        ZStack(alignment: .bottomLeading) {
            RecipeImageView(url: URL(string: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=1400"))
                .frame(height: 286)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            LinearGradient(
                colors: [.clear, .black.opacity(0.16), .black.opacity(0.76)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            VStack(alignment: .leading, spacing: 13) {
                Text(greeting)
                    .font(.system(size: 29, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text("Your preferences keep recipes tuned to you.")
                    .font(DSTypography.body)
                    .foregroundStyle(.white.opacity(0.78))

                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 8) {
                            profileStat(viewModel.defaultGoal.title, label: "Goal", systemImage: "figure.run")
                            profileStat(effectiveDiet.title, label: "Diet", systemImage: "fork.knife")
                            profileStat(viewModel.useMockGeneration ? "Mock session" : "Backend", label: "Mode", systemImage: authStateIcon)
                        }
                    } else {
                        HStack(spacing: 8) {
                            profileStat(viewModel.defaultGoal.title, label: "Goal", systemImage: "figure.run")
                            profileStat(effectiveDiet.title, label: "Diet", systemImage: "fork.knife")
                            profileStat(viewModel.useMockGeneration ? "Mock session" : "Backend", label: "Mode", systemImage: authStateIcon)
                        }
                    }
                }
                .padding(.top, 2)
            }
            .padding(18)
        }
        .shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 14)
    }

    private var greeting: String {
        let name = viewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hour = Calendar.current.component(.hour, from: .now)
        let greetingKey: String
        switch hour {
        case 5..<12: greetingKey = "Good morning"
        case 12..<18: greetingKey = "Good afternoon"
        default: greetingKey = "Good evening"
        }
        let greeting = String(localized: String.LocalizationValue(greetingKey))
        return name.isEmpty ? greeting : "\(greeting), \(name)"
    }

    private var editableNameRow: some View {
        profileRow(icon: "person", title: "Name") {
            TextField("Name", text: $viewModel.displayName)
                .multilineTextAlignment(.trailing)
                .font(DSTypography.body)
                .foregroundStyle(DSColor.textSecondary)
                .tint(DSColor.accent)
                .frame(minWidth: 80, maxWidth: 220, alignment: .trailing)
        }
    }

    private var dietRow: some View {
        profileMenuRow(icon: "fork.knife", title: "Diet", value: effectiveDiet.profileTitle) {
            ForEach(profileDiets) { diet in
                Button(diet.profileTitle) {
                    Task { await viewModel.setDiet(diet) }
                }
            }
        }
    }

    private var allergensRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            profileRow(icon: "cross.case", title: "Allergens") {
                HStack(spacing: 8) {
                    TextField("Add", text: $allergenInput)
                        .multilineTextAlignment(.trailing)
                        .font(DSTypography.body)
                        .foregroundStyle(DSColor.textSecondary)
                        .tint(DSColor.accent)
                        .submitLabel(.done)
                        .onSubmit(addAllergen)

                    if canAddAllergen {
                        Button(action: addAllergen) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(DSColor.accent)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            if !viewModel.allergens.isEmpty {
                FlexibleChipGrid(values: viewModel.allergens) { allergen in
                    withAnimation(DSMotion.list) {
                        viewModel.removeAllergen(allergen)
                    }
                }
                .padding(.leading, 34)
                .transition(.opacity.combined(with: .offset(y: -8)))
            }
        }
        .padding(.vertical, 14)
    }

    private var appearanceRow: some View {
        profileMenuRow(icon: "circle.lefthalf.filled", title: "Appearance", value: viewModel.appTheme.title) {
            ForEach(AppTheme.allCases) { theme in
                Button(theme.title) {
                    withAnimation(DSMotion.snappy) {
                        viewModel.setTheme(theme)
                    }
                }
            }
        }
    }

    private var languageRow: some View {
        profileMenuRow(icon: "globe", title: "Language", value: viewModel.appLanguage.settingsTitle) {
            ForEach(AppLanguage.allCases) { language in
                Button(language.settingsTitle) {
                    withAnimation(DSMotion.snappy) {
                        viewModel.setLanguage(language)
                    }
                }
            }
        }
    }

    private func profileMenuRow<Content: View>(
        icon: String,
        title: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            profileRow(icon: icon, title: title) {
                HStack(spacing: 7) {
                    Text(LocalizedStringKey(value))
                        .font(DSTypography.body)
                        .foregroundStyle(DSColor.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DSColor.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func profileRow<Content: View>(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> Content
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                rowTitle(icon: icon, title: title)
                Spacer(minLength: 12)
                trailing()
                    .frame(maxWidth: 220, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 8) {
                rowTitle(icon: icon, title: title)
                trailing()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 16)
    }

    private func rowTitle(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DSColor.accent)
                .frame(width: 22)

            Text(LocalizedStringKey(title))
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(DSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func profileStat(_ value: String, label: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(value))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(LocalizedStringKey(label))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .opacity(0.68)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(.white.opacity(0.13))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.14), lineWidth: 0.6)
        }
    }

    private func aboutRow(_ title: String, value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(DSColor.textPrimary)
            Spacer()
            if !value.isEmpty {
                Text(LocalizedStringKey(value))
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColor.textTertiary)
            }
        }
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var privacyPolicyRow: some View {
        if let url = AppConfiguration.privacyPolicyURL {
            Button {
                openURL(url)
            } label: {
                HStack {
                    Text("Privacy Policy")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(DSColor.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DSColor.textTertiary)
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            HStack {
                Text("Privacy Policy")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(DSColor.textPrimary)
                Spacer()
                Text("URL required")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColor.textTertiary)
            }
            .padding(.vertical, 14)
            .accessibilityHint("Configure PrivacyPolicyURL in Info.plist before release.")
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(DSColor.border.opacity(0.34))
            .frame(height: 1)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var profileDiets: [DietaryPreference] {
        [.regular, .vegetarian, .vegan]
    }

    private var effectiveDiet: DietaryPreference {
        profileDiets.contains(viewModel.dietaryPreference)
            ? viewModel.dietaryPreference
            : .regular
    }

    private var canAddAllergen: Bool {
        !allergenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addAllergen() {
        withAnimation(DSMotion.list) {
            viewModel.addAllergen(allergenInput)
            allergenInput = ""
        }
    }

    private func settingSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(DSColor.textPrimary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func profileTextField(
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

    private func segmentedOptions(
        _ options: [(String, String)],
        selectedID: String,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.0) { id, title in
                Button {
                    onSelect(id)
                } label: {
                    Text(LocalizedStringKey(title))
                        .font(DSTypography.caption)
                        .foregroundStyle(id == selectedID ? DSColor.accent : DSColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(id == selectedID ? DSColor.accentSurface : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(DSColor.elevatedCard)
        .clipShape(Capsule())
    }
}

private struct FlexibleChipGrid: View {
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
    var profileTitle: String {
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

private extension AppLanguage {
    var settingsTitle: String {
        switch self {
        case .system: "System Language"
        case .english: "English"
        case .russian: "Russian"
        }
    }
}
