import SwiftUI
import AVFoundation

/// Wraps the front camera in a SwiftUI view for the brushing screen.
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }

        // Only configure when already authorized (BrushView shows this only after permission is granted).
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            return view
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return view
        }
        session.addInput(input)

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.previewLayer = layer
        view.layer.insertSublayer(layer, at: 0)

        context.coordinator.session = session
        context.coordinator.previewLayer = layer
        DispatchQueue.global(qos: .userInitiated).async { [weak session] in
            session?.startRunning()
        }
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Frame is set in layoutSubviews of the host view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
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
