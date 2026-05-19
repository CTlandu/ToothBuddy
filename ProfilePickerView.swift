import SwiftUI
import ToothBuddyCore

extension ProfileColor {
    var color: Color {
        switch self {
        case .coral:     return Color(red: 1.00, green: 0.45, blue: 0.42)
        case .tangerine: return Color(red: 1.00, green: 0.60, blue: 0.25)
        case .sunshine:  return Color(red: 1.00, green: 0.80, blue: 0.25)
        case .lime:      return Color(red: 0.55, green: 0.80, blue: 0.30)
        case .mint:      return Color(red: 0.30, green: 0.80, blue: 0.65)
        case .sky:       return Color(red: 0.35, green: 0.65, blue: 0.95)
        case .grape:     return Color(red: 0.62, green: 0.45, blue: 0.90)
        case .bubblegum: return Color(red: 0.95, green: 0.50, blue: 0.78)
        }
    }
}

/// Profile gate (first run = must create one) and switcher (sheet, can dismiss).
struct ProfilePickerView: View {
    @ObservedObject var store: ProfileStore
    /// When true this is the mandatory first-run gate (no dismiss, no cancel).
    let isGate: Bool
    var onDone: () -> Void = {}

    @State private var creating = false

    var body: some View {
        VStack(spacing: 0) {
            Text(isGate ? "Who's brushing?" : "Switch profile")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top, 28)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.profiles) { p in
                        HStack(spacing: 10) {
                            Button {
                                store.setActive(p.id)
                                onDone()
                            } label: { ProfileRow(profile: p,
                                                   selected: p.id == store.activeProfileID) }
                            .buttonStyle(.plain)
                            // Spec 05 §6.1 — per-profile experience mode. Flipping one
                            // profile never changes a sibling on the same device.
                            Menu {
                                Picker("Mode", selection: Binding(
                                    get: { p.mode },
                                    set: { store.setMode($0, for: p.id) })) {
                                    Text("Kid").tag(ProfileMode.kid)
                                    Text("Adult").tag(ProfileMode.adult)
                                }
                            } label: {
                                Image(systemName: p.mode == .adult
                                      ? "person.fill" : "figure.child")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.10))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    Button { creating = true } label: {
                        Label("Add profile", systemImage: "plus.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }

            if !isGate {
                Button("Done", action: onDone)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $creating) {
            CreateProfileView(store: store) { created in
                creating = false
                if created, isGate { onDone() }
            }
        }
    }
}

private struct ProfileRow: View {
    let profile: Profile
    let selected: Bool
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: profile.symbol.systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(profile.colorTag.color)
                .clipShape(Circle())
            Text(profile.name).font(.system(size: 18, weight: .semibold))
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill").foregroundColor(profile.colorTag.color)
            }
        }
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CreateProfileView: View {
    @ObservedObject var store: ProfileStore
    var onFinish: (_ created: Bool) -> Void

    @State private var name = ""
    @State private var color: ProfileColor = .sky
    @State private var symbol: ProfileSymbol = .star
    @State private var mode: ProfileMode = .kid
    @Environment(\.dismiss) private var dismiss

    private let cols = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("e.g. Mia", text: $name) }
                Section("Mode") {
                    Picker("Experience", selection: $mode) {
                        Text("Kid").tag(ProfileMode.kid)
                        Text("Adult").tag(ProfileMode.adult)
                    }
                    .pickerStyle(.segmented)
                    Text(mode == .adult
                         ? "Calm, no games or stars — just a quiet streak."
                         : "Playful — Sugar Bugs, stars and a cheery voice.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Section("Color") { colorGrid }
                Section("Avatar") { avatarGrid }
            }
            .navigationTitle("New profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    private var colorGrid: some View {
        LazyVGrid(columns: cols) {
            ForEach(ProfileColor.allCases, id: \.self) { c in
                Circle()
                    .fill(c.color)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().strokeBorder(.primary, lineWidth: c == color ? 3 : 0))
                    .onTapGesture { color = c }
            }
        }
        .padding(.vertical, 4)
    }

    private var avatarGrid: some View {
        LazyVGrid(columns: cols) {
            ForEach(ProfileSymbol.allCases, id: \.self) { s in
                Image(systemName: s.systemImage)
                    .font(.system(size: 22))
                    .frame(width: 40, height: 40)
                    .background(s == symbol ? color.color.opacity(0.25) : Color.clear)
                    .clipShape(Circle())
                    .onTapGesture { symbol = s }
            }
        }
        .padding(.vertical, 4)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Create") {
                if store.createProfile(name: name, color: color, symbol: symbol,
                                       mode: mode) != nil {
                    onFinish(true)
                    dismiss()
                }
            }
            .disabled(Profile.validatedName(name) == nil)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { onFinish(false); dismiss() }
        }
    }
}
