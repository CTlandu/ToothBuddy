// AUDIT 2026-05-28 (Plan U1): @preconcurrency on AVFoundation is still the right choice.
// AVFoundation pre-dates Swift Concurrency and ships a mix of un-audited Sendable
// annotations; @preconcurrency suppresses the noisy warnings without weakening our own
// isolation. The supported alternative is "wait for Apple to finish auditing the SDK".
@preconcurrency import AVFoundation
import QuartzCore
import ToothBuddyCore

/// The single owner of the app's one `AVCaptureSession` (Spec 04.2 §3). Both the selfie
/// preview and the Vision data output hang off this one session, so the front camera is
/// claimed exactly once. All session/IO mutation is confined to `sessionQueue`; the
/// preview layer is only touched on the main queue. `@unchecked Sendable` with those
/// confinement invariants documented and upheld.
//
// AUDIT 2026-05-28 (Plan U1): @unchecked Sendable is still the right choice. The
// Sendable safety here is enforced by `sessionQueue` (all mutating ops) and the
// main queue (only `previewLayer.frame`) — boundaries the compiler can't see. The
// supported alternatives are (a) wrap state in an actor — but then every SwiftUI
// caller becomes async and the AVCaptureSession.startRunning() blocking call still
// has to live somewhere off-main, (b) split into multiple actors — adds surface area
// for the same safety guarantee. Confinement is simpler and equally safe.
final class CameraService: @unchecked Sendable {
    static let shared = CameraService()   // type is @unchecked Sendable

    private let sessionQueue = DispatchQueue(label: "com.ctlandu.ToothBuddy.cameraSession")
    private let videoQueue   = DispatchQueue(label: "com.ctlandu.ToothBuddy.cameraVideo")
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processor = VisionFrameProcessor()
    private var configured = false

    /// Eagerly created so `CameraPreviewView` can read it on main immediately.
    /// Only `.frame` is mutated on main; `.session` is set once (on main, see configure()).
    let previewLayer = AVCaptureVideoPreviewLayer()

    private init() {
        previewLayer.videoGravity = .resizeAspectFill
    }

    var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    /// Begin (or keep) the live preview. Idempotent. Called when the brushing screen is
    /// shown, independent of whether a session is active. No-ops cleanly if unauthorized.
    func startPreview() {
        sessionQueue.async { [self] in
            configureIfNeeded()
            if isAuthorized, !session.isRunning {
                session.startRunning()   // blocks — correct on sessionQueue, never main
            }
        }
    }

    /// Attach Vision frame delivery (while a brushing session is active). Idempotent;
    /// ensures the preview is running too.
    func attachVision(sink: @escaping @Sendable (ZoneSample) -> Void) {
        sessionQueue.async { [self] in
            configureIfNeeded()
            processor.sink = sink
            if isAuthorized, !session.isRunning { session.startRunning() }
        }
    }

    /// Detach Vision but keep the preview running (user still sees themselves between
    /// sessions / on the done screen).
    func detachVision() {
        sessionQueue.async { [self] in processor.sink = nil }
    }

    /// Fully release the camera (battery/privacy). Called when the brushing screen is
    /// torn down. Idempotent; safe even if never started.
    func stop() {
        sessionQueue.async { [self] in
            processor.sink = nil
            if session.isRunning { session.stopRunning() }
        }
    }

    // MARK: - Configuration (sessionQueue only, exactly once)

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        if isAuthorized,
           let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)

            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings =
                [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.setSampleBufferDelegate(processor, queue: videoQueue)
            if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

            // Data-output connection: portrait, NOT mirrored (we mirror in math, §6.4).
            if let dc = videoOutput.connection(with: .video) {
                applyPortrait(dc, mirrored: false)
            }
        }
        session.commitConfiguration()

        // Preview layer must be wired on the main queue (Apple guidance).
        DispatchQueue.main.async { [self] in
            previewLayer.session = session
            if let pc = previewLayer.connection {
                applyPortrait(pc, mirrored: true)   // selfie mirror for the user
            }
        }
    }

    private func applyPortrait(_ c: AVCaptureConnection, mirrored: Bool) {
        if #available(iOS 17.0, *) {
            if c.isVideoRotationAngleSupported(90) { c.videoRotationAngle = 90 } // portrait
        } else {
            if c.isVideoOrientationSupported { c.videoOrientation = .portrait }
        }
        if c.isVideoMirroringSupported {
            c.automaticallyAdjustsVideoMirroring = false
            c.isVideoMirrored = mirrored
        }
    }
}
