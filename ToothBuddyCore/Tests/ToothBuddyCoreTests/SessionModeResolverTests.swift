import XCTest
@testable import ToothBuddyCore

/// U4 — mirror mode degrades honestly to audio when the camera is unavailable; audio mode
/// is never "degraded"; the result drives BrushView's render branch (no black frame).
final class SessionModeResolverTests: XCTestCase {

    func testMirrorAuthorizedRunsCamera() {
        let m = SessionModeResolver.resolve(requestedMirror: true, authorization: .authorized)
        XCTAssertEqual(m, EffectiveSessionMode(useCamera: true, degraded: false))
    }

    func testMirrorDeniedDegradesToAudio() {
        let m = SessionModeResolver.resolve(requestedMirror: true, authorization: .denied)
        XCTAssertEqual(m, EffectiveSessionMode(useCamera: false, degraded: true))
    }

    func testMirrorRestrictedDegradesToAudio() {
        let m = SessionModeResolver.resolve(requestedMirror: true, authorization: .restricted)
        XCTAssertEqual(m, EffectiveSessionMode(useCamera: false, degraded: true))
    }

    func testMirrorNotDeterminedIsOptimisticCamera() {
        // Optimistic: caller gates on the prompt and re-resolves with the real answer.
        let m = SessionModeResolver.resolve(requestedMirror: true, authorization: .notDetermined)
        XCTAssertEqual(m, EffectiveSessionMode(useCamera: true, degraded: false))
    }

    func testAudioRequestedNeverUsesCameraNeverDegraded() {
        for auth: CameraAuthorization in [.authorized, .denied, .restricted, .notDetermined] {
            let m = SessionModeResolver.resolve(requestedMirror: false, authorization: auth)
            XCTAssertEqual(m, EffectiveSessionMode(useCamera: false, degraded: false),
                           "audio request must stay audio for \(auth)")
        }
    }
}
