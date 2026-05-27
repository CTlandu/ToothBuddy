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
            // Hero: Buddy logo + title
            VStack(spacing: 8) {
                BuddyView()
                    .frame(width: 72, height: 82)
                Text(isGate ? "Who's brushing?" : "Switch profile")
                    .font(Duo.Fnt.ebd(26))
                    .tracking(0.3)
                    .foregroundColor(Duo.ink)
            }
            .padding(.top, 28)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 14) {
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
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Duo.ink)
                                        .offset(y: 3)
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Duo.ink, lineWidth: 2)
                                        )
                                    Image(systemName: p.mode == .adult
                                          ? "person.fill" : "figure.child")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(Duo.ink)
                                }
                                .frame(width: 44, height: 44)
                            }
                        }
                    }
                    Button { creating = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Add profile")
                                .font(Duo.Fnt.ebd(15))
                                .tracking(0.5)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(DuoButtonStyle(role: .primary))
                    .padding(.top, 6)
                }
                .padding(20)
            }

            if !isGate {
                DuoButton("DONE", role: .secondary) { onDone() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .background(Duo.pageBackground.ignoresSafeArea())
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
            ZStack {
                Circle().fill(Duo.ink).offset(y: 2)
                Image(systemName: profile.symbol.systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(profile.colorTag.color))
                    .overlay(Circle().stroke(Duo.ink, lineWidth: 2))
            }
            .frame(width: 46, height: 48)
            Text(profile.name)
                .font(Duo.Fnt.ebd(18))
                .foregroundColor(Duo.ink)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Duo.green)
            }
        }
        .duoCard(face: .white, padding: 14)
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
    private var canCreate: Bool { Profile.validatedName(name) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    nameCard
                    modeCard
                    colorCard
                    avatarCard
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .background(Duo.pageBackground.ignoresSafeArea())
            .navigationTitle("New profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    private var nameCard: some View {
        DuoCard(face: .white, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(Duo.Fnt.ebd(11))
                    .tracking(0.8)
                    .foregroundColor(Duo.muted)
                TextField("e.g. Mia", text: $name)
                    .font(Duo.Fnt.ebd(18))
                    .foregroundColor(Duo.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Duo.stoneLight.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Duo.ink.opacity(0.4), lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var modeCard: some View {
        DuoCard(face: .white, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("EXPERIENCE")
                    .font(Duo.Fnt.ebd(11))
                    .tracking(0.8)
                    .foregroundColor(Duo.muted)
                HStack(spacing: 10) {
                    modeButton(.kid, label: "KID 🌱")
                    modeButton(.adult, label: "ADULT")
                }
                Text(mode == .adult
                     ? "Calm — no games or stars, just a quiet streak."
                     : "Playful — Sugar Bugs, stars and a cheery voice.")
                    .font(Duo.Fnt.sbd(12))
                    .foregroundColor(Duo.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func modeButton(_ m: ProfileMode, label: String) -> some View {
        let selected = mode == m
        return Button { mode = m } label: {
            Text(label)
                .font(Duo.Fnt.ebd(13))
                .tracking(0.4)
                .foregroundColor(selected ? .white : Duo.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(DuoModePickerStyle(selected: selected))
    }

    private var colorCard: some View {
        DuoCard(face: .white, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("COLOR")
                    .font(Duo.Fnt.ebd(11))
                    .tracking(0.8)
                    .foregroundColor(Duo.muted)
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(ProfileColor.allCases, id: \.self) { c in
                        Button { color = c } label: {
                            ZStack {
                                if c == color {
                                    Circle().fill(Duo.ink).offset(y: 2)
                                }
                                Circle()
                                    .fill(c.color)
                                    .overlay(Circle().stroke(Duo.ink,
                                        lineWidth: c == color ? 2.5 : 1.5))
                            }
                            .frame(width: 40, height: 42)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var avatarCard: some View {
        DuoCard(face: .white, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("AVATAR")
                    .font(Duo.Fnt.ebd(11))
                    .tracking(0.8)
                    .foregroundColor(Duo.muted)
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(ProfileSymbol.allCases, id: \.self) { s in
                        Button { symbol = s } label: {
                            ZStack {
                                if s == symbol {
                                    Circle().fill(Duo.ink).offset(y: 2)
                                }
                                Circle()
                                    .fill(s == symbol ? color.color : Color.white)
                                    .overlay(Circle().stroke(Duo.ink,
                                        lineWidth: s == symbol ? 2.5 : 1.5))
                                Image(systemName: s.systemImage)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(s == symbol ? .white : Duo.ink)
                            }
                            .frame(width: 44, height: 46)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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
            .font(Duo.Fnt.ebd(15))
            .foregroundColor(canCreate ? Duo.green : Duo.muted)
            .disabled(!canCreate)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { onFinish(false); dismiss() }
                .font(Duo.Fnt.sbd(15))
                .foregroundColor(Duo.muted)
        }
    }
}

/// Button style for the kid/adult mode picker — selected = green chunky face,
/// unselected = white chunky face. Both share the press-to-flatten animation.
private struct DuoModePickerStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected ? Duo.greenShadow : Duo.ink)
                .offset(y: configuration.isPressed ? 0 : 3)

            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? Duo.green : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Duo.ink, lineWidth: 2)
                )
                .offset(y: configuration.isPressed ? 3 : 0)
        }
        .animation(.spring(response: 0.18, dampingFraction: 0.7),
                   value: configuration.isPressed)
    }
}
