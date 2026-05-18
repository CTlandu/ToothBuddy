import Foundation

/// A spoken cue at a point in the brushing session (Spec 03 §5.3).
public enum CueKind: String, Sendable, Equatable {
    case intro, quadrant, content, encourage, wrap
}

public struct ScriptCue: Equatable, Sendable {
    public let atSecond: Int
    public let kind: CueKind
    public let text: String
    public init(atSecond: Int, kind: CueKind, text: String) {
        self.atSecond = atSecond; self.kind = kind; self.text = text
    }
}

/// Pure, deterministic 2-minute session timeline. The app drives `VoiceCoach` from this;
/// speech is app-layer smoke. Spec 03 §5.3 / AC5.
public enum SessionScript {

    private static let quadrantNames = [
        "upper left", "upper right", "lower left", "lower right"
    ]

    public static func build(durationSeconds: Int,
                             tone: ContentTone,
                             content: ContentItem?,
                             calendar: Calendar) -> [ScriptCue] {
        let duration = max(20, durationSeconds)          // sane floor
        let q = duration / 4
        var cues: [ScriptCue] = []

        cues.append(ScriptCue(
            atSecond: 0, kind: .intro,
            text: tone == .playful
                ? "Brushing time! Grab your brush and let's beat the sugar bugs."
                : "Two-minute brush. Let's begin."))

        for i in 0..<4 {
            cues.append(ScriptCue(
                atSecond: i * q, kind: .quadrant,
                text: "Now the \(quadrantNames[i]) — small gentle circles."))
        }

        if let content {
            cues.append(ScriptCue(atSecond: 2 * q, kind: .content, text: content.text))
        }

        cues.append(ScriptCue(
            atSecond: min(duration - 1, 3 * q + q / 2), kind: .encourage,
            text: tone == .playful ? "Almost there, keep scrubbing!" : "Almost done."))

        cues.append(ScriptCue(
            atSecond: duration, kind: .wrap,
            text: tone == .playful
                ? "Awesome job! Spit, don't rinse — see you tonight!"
                : "Done. Spit, don't rinse."))

        // Stable order: by time, then a fixed kind rank for ties (intro→quadrant→
        // content→encourage→wrap) so output is deterministic.
        func rank(_ k: CueKind) -> Int {
            switch k { case .intro: 0; case .quadrant: 1; case .content: 2
                       case .encourage: 3; case .wrap: 4 }
        }
        return cues.enumerated().sorted {
            $0.element.atSecond != $1.element.atSecond
                ? $0.element.atSecond < $1.element.atSecond
                : rank($0.element.kind) != rank($1.element.kind)
                    ? rank($0.element.kind) < rank($1.element.kind)
                    : $0.offset < $1.offset
        }.map(\.element)
    }
}
