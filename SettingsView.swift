import SwiftUI
import ToothBuddyCore

/// User-facing preferences (U7). Replaces the kid/adult mode split — everything defaults on,
/// the user turns off what they don't want. Visual polish deferred; a plain Form for now.
struct SettingsView: View {
    @StateObject private var prefs = PreferencesStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Brushing") {
                    Picker("Guidance", selection: $prefs.sessionMode) {
                        Text("Voice only (eyes-free)").tag(PreferencesStore.SessionMode.audio)
                        Text("Smart mirror (camera)").tag(PreferencesStore.SessionMode.mirror)
                    }
                    Picker("Session length", selection: $prefs.targetSeconds) {
                        Text("2 minutes").tag(120)
                        Text("3 minutes").tag(180)
                    }
                    Toggle("Voice guidance", isOn: $prefs.voiceEnabled)
                    Toggle("Sugar Bugs game", isOn: $prefs.gameEnabled)
                }

                Section("Content & rewards") {
                    Picker("Content style", selection: $prefs.contentTone) {
                        Text("Playful (jokes & stories)").tag(ContentTone.playful)
                        Text("Essentials (tips only)").tag(ContentTone.essentials)
                    }
                    Toggle("Celebrations & stars", isOn: $prefs.celebrationsEnabled)
                    Toggle("Levels & achievements", isOn: $prefs.showLevelAchievements)
                    Toggle("Habit curve", isOn: $prefs.showHabitCurve)
                }

                Section("Health") {
                    Toggle("Connect to Apple Health", isOn: $prefs.healthConnectEnabled)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
