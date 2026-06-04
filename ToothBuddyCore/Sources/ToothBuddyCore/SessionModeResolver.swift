import Foundation

/// Phase 1.5 / U4 — coarse camera-permission state, mapped from `AVAuthorizationStatus`
/// by the app layer so this decision stays pure and CLI-testable.
public enum CameraAuthorization: Sendable, Equatable {
    case authorized
    case denied
    case restricted
    case notDetermined
}

/// The mode a session will actually run in, given what the user asked for and whether the
/// camera is usable.
public struct EffectiveSessionMode: Sendable, Equatable {
    /// True = smart-mirror (camera on). False = audio-first (no camera).
    public let useCamera: Bool
    /// True only when the user asked for the mirror but the camera is unavailable — the
    /// signal to surface a non-blocking "running audio-only" notice instead of a black frame.
    public let degraded: Bool

    public init(useCamera: Bool, degraded: Bool) {
        self.useCamera = useCamera
        self.degraded = degraded
    }
}

/// Decides the effective session mode (U4). Keeps the "camera denied → honest audio
/// degradation, never a black preview" rule as a pure function so BrushView only feeds facts.
/// Mirrors the codebase convention of pushing decidable logic into Core (see
/// `CameraVerification`, `HealthExportDecider`).
public enum SessionModeResolver {
    /// - Parameters:
    ///   - requestedMirror: did the user pick the smart-mirror (camera) mode?
    ///   - authorization: current camera permission state.
    /// - Returns: the mode to actually run, and whether to show the degraded notice.
    ///
    /// `notDetermined` resolves optimistically to camera-on: the caller is expected to gate
    /// session start on the permission prompt and re-resolve with the user's actual answer,
    /// so a session is never silently stamped guided-only while the user is about to grant.
    public static func resolve(requestedMirror: Bool,
                               authorization: CameraAuthorization) -> EffectiveSessionMode {
        guard requestedMirror else {
            return EffectiveSessionMode(useCamera: false, degraded: false)
        }
        switch authorization {
        case .authorized:
            return EffectiveSessionMode(useCamera: true, degraded: false)
        case .denied, .restricted:
            return EffectiveSessionMode(useCamera: false, degraded: true)
        case .notDetermined:
            return EffectiveSessionMode(useCamera: true, degraded: false)
        }
    }
}
