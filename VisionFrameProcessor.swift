@preconcurrency import AVFoundation
@preconcurrency import Vision
import CoreMedia
import QuartzCore
import ToothBuddyCore

/// Runs on the camera data-output queue (never main). Per throttled frame: runs Vision,
/// builds a `Sendable` `ZoneSample`, hands it to the sink. Nothing non-Sendable leaves
/// this queue. All mutable state is either queue-confined (only touched in the delegate
/// callback on the single serial video queue) or lock-protected (`sink`). Spec 04.2 §5–6.
final class VisionFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,
                                  @unchecked Sendable {

    // MARK: Sink (set from sessionQueue, read from videoQueue → lock-protected)
    private let sinkLock = NSLock()
    private var _sink: (@Sendable (ZoneSample) -> Void)?
    var sink: (@Sendable (ZoneSample) -> Void)? {
        get { sinkLock.lock(); defer { sinkLock.unlock() }; return _sink }
        set { sinkLock.lock(); _sink = newValue; sinkLock.unlock() }
    }

    // MARK: Queue-confined state (only the delegate callback, one serial queue)
    private let faceRequest = VNDetectFaceLandmarksRequest()
    private let handRequest: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest(); r.maximumHandCount = 2; return r
    }()
    private var lastProcessed: CFTimeInterval = 0
    private var prevHand: CGPoint?
    private var motion: Double = 0

    // Tunables (Spec 04.2 §10)
    private let maxFPS: Double = 12
    private let handConfidenceMin: VNConfidence = 0.3
    private let motionFullScale: Double = 0.06
    private let mouthFallbackHeightFrac: Double = 0.30

    // DEVICE-TUNE (Spec 04.2 §6.4): the handler orientation `.leftMirrored` already
    // presents Vision coords upright + mirrored to match the selfie preview, so we only
    // flip Y (Vision is bottom-left origin; Core UnitPoint2D is top-left). If, on a real
    // device, left/right feels reversed flip `mirrorX`; if up/down feels reversed flip
    // `flipY`. One-line change, deliberately isolated so the user's smoke is painless.
    private let mirrorX = false
    private let flipY = true

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Throttle.
        let now = CACurrentMediaTime()
        guard now - lastProcessed >= 1.0 / maxFPS else { return }
        lastProcessed = now
        guard let sink = self.sink,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .leftMirrored, options: [:])
        do {
            try handler.perform([faceRequest, handRequest])
        } catch {
            return   // never crash on a bad frame
        }

        let face = makeFaceSignal()
        let hand = makeHandSignal()
        sink(ZoneSample(face: face, hand: hand, atSeconds: now))
    }

    // MARK: Face

    private func makeFaceSignal() -> FaceSignal {
        guard let obs = (faceRequest.results)?
            .max(by: { $0.boundingBox.area < $1.boundingBox.area }) else {
            return FaceSignal(isPresent: false)
        }
        let bb = obs.boundingBox
        let mouthVision: CGPoint
        if let lips = obs.landmarks?.outerLips, lips.pointCount > 0 {
            let pts = lips.normalizedPoints
            let sx = pts.reduce(0) { $0 + Double($1.x) } / Double(pts.count)
            let sy = pts.reduce(0) { $0 + Double($1.y) } / Double(pts.count)
            mouthVision = CGPoint(x: bb.origin.x + CGFloat(sx) * bb.size.width,
                                  y: bb.origin.y + CGFloat(sy) * bb.size.height)
        } else {
            // Lower third of the face box ≈ mouth (Vision y is bottom-up).
            mouthVision = CGPoint(
                x: bb.midX,
                y: bb.origin.y + CGFloat(mouthFallbackHeightFrac) * bb.size.height)
        }
        let yaw = obs.yaw.map(\.doubleValue)
        return FaceSignal(isPresent: true,
                          mouthCenter: unit(mouthVision),
                          faceYaw: yaw)
    }

    // MARK: Hand

    private func makeHandSignal() -> HandSignal {
        guard let obs = (handRequest.results)?
            .max(by: { $0.confidence < $1.confidence }),
              obs.confidence >= handConfidenceMin else {
            motion *= 0.5                 // decay toward 0 while hand absent
            prevHand = nil
            return HandSignal(isPresent: false, motionEnergy: clamp01(motion))
        }
        let point = handPoint(obs)
        guard let p = point else {
            motion *= 0.5
            prevHand = nil
            return HandSignal(isPresent: false, motionEnergy: clamp01(motion))
        }
        if let prev = prevHand {
            let d = Double(hypot(p.x - prev.x, p.y - prev.y))
            motion = 0.6 * motion + 0.4 * min(1.0, d / motionFullScale)
        }
        prevHand = p
        return HandSignal(isPresent: true,
                          position: unit(p),
                          motionEnergy: clamp01(motion))
    }

    private func handPoint(_ obs: VNHumanHandPoseObservation) -> CGPoint? {
        if let w = try? obs.recognizedPoint(.wrist), w.confidence >= handConfidenceMin {
            return w.location
        }
        if let m = try? obs.recognizedPoint(.middleMCP), m.confidence >= handConfidenceMin {
            return m.location
        }
        return nil
    }

    // MARK: Coordinate transform (Spec 04.2 §6.4)

    private func unit(_ p: CGPoint) -> UnitPoint2D {
        let x = mirrorX ? 1.0 - Double(p.x) : Double(p.x)
        let y = flipY ? 1.0 - Double(p.y) : Double(p.y)
        return UnitPoint2D(x: clamp01(x), y: clamp01(y))
    }

    private func clamp01(_ v: Double) -> Double { max(0, min(1, v)) }
}

private extension CGRect {
    var area: CGFloat { width * height }
}
