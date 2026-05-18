import SwiftUI
import AVFoundation

/// Front-camera selfie preview for the brushing screen. Displays the **single shared**
/// `CameraService` session (Spec 04.2 §3/§9) — it does NOT create its own session, so the
/// camera is claimed exactly once (also feeding Vision). Fully functional / black
/// placeholder when unauthorized; no crash, no leak.
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        let layer = CameraService.shared.previewLayer
        layer.removeFromSuperlayer()           // safe if re-mounted
        view.previewLayer = layer
        view.layer.insertSublayer(layer, at: 0)
        CameraService.shared.startPreview()    // live as soon as the screen shows
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Frame is set in layoutSubviews of the host view.
    }

    /// Brushing screen torn down → fully release the camera (battery / privacy dot).
    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: ()) {
        CameraService.shared.stop()
    }
}

/// Host view that updates the preview layer frame when its bounds change.
final class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
