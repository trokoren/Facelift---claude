import AVFoundation
import Observation

/// Front-camera capture session used during the face scan.
@Observable
final class CameraService {
    enum Status: Equatable {
        case idle
        case running
        case denied
        case unavailable
    }

    private(set) var status: Status = .idle

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "app.facelift.camera")

    func start() async {
        guard status == .idle else { return }

        let granted: Bool
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            granted = true
        case .notDetermined:
            granted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            granted = false
        }
        guard granted else {
            status = .denied
            return
        }

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        let devices = discovery.devices
        guard let device = devices.first(where: { $0.position == .front }) ?? devices.first,
              let input = try? AVCaptureDeviceInput(device: device) else {
            status = .unavailable
            return
        }

        let configured = await Self.configure(session: session, input: input, queue: sessionQueue)
        status = configured ? .running : .unavailable
    }

    func stop() {
        let session = self.session
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    nonisolated private static func configure(session: AVCaptureSession, input: AVCaptureDeviceInput, queue: DispatchQueue) async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async {
                session.beginConfiguration()
                if session.canSetSessionPreset(.high) {
                    session.sessionPreset = .high
                }
                guard session.canAddInput(input) else {
                    session.commitConfiguration()
                    continuation.resume(returning: false)
                    return
                }
                session.addInput(input)
                session.commitConfiguration()
                session.startRunning()
                continuation.resume(returning: true)
            }
        }
    }
}
