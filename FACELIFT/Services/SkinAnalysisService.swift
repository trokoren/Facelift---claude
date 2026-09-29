import UIKit
import Vision

struct SkinAnalysisError: LocalizedError {
    let message: String
    var errorDescription: String? { message }

    static let generic = SkinAnalysisError(message: "We couldn't read that scan. Please try again in bright, even light.")
    static let offline = SkinAnalysisError(message: "We couldn't reach our servers. Check your connection and try again.")
}

/// Sends the straight-on photo to our server (Supabase function "analyze-skin"), which reads
/// it with YouCam's skin analysis and returns a score per marker. The photo is only held in
/// memory on the phone.
enum SkinAnalysisService {
    static func analyze(_ photo: UIImage, mode: ScanLab.Mode, context: [String: Any]) async throws -> SkinReport {
        guard let url = Backend.functionURL("analyze-skin") else { throw SkinAnalysisError.generic }
        guard let prepared = prepare(photo),
              let jpeg = prepared.jpegData(compressionQuality: 0.9) else { throw SkinAnalysisError.generic }

        var request = URLRequest(url: url, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Backend.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Backend.anonKey, forHTTPHeaderField: "apikey")
        let body: [String: Any] = [
            "image": jpeg.base64EncodedString(),
            "width": Int(prepared.size.width * prepared.scale),
            "height": Int(prepared.size.height * prepared.scale),
            "mode": mode.rawValue,
            "context": context
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let result: (Data, URLResponse)
        do {
            result = try await URLSession.shared.data(for: request)
        } catch {
            throw SkinAnalysisError.offline
        }
        let data = result.0
        let status = (result.1 as? HTTPURLResponse)?.statusCode ?? 0

        guard status == 200 else {
            struct Failure: Decodable { let error: String? }
            // 422 carries a message written for her ("hold your phone closer"). Anything else
            // is a server problem, so keep the wording general.
            if status == 422, let message = (try? JSONDecoder().decode(Failure.self, from: data))?.error {
                throw SkinAnalysisError(message: message)
            }
            #if DEBUG
            print("analyze-skin failed (\(status)):", String(data: data, encoding: .utf8) ?? "")
            #endif
            throw SkinAnalysisError.generic
        }

        guard let report = try? JSONDecoder().decode(SkinReport.self, from: data), report.isUsable else {
            throw SkinAnalysisError.generic
        }
        return report
    }

    /// Crops around her face so it fills about 70% of the photo's width (what YouCam reads
    /// best), keeps a 3:4 portrait frame, and caps the long side at 2560 px.
    static func prepare(_ photo: UIImage) -> UIImage? {
        guard let cgImage = photo.cgImage else { return nil }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        var crop = CGRect(x: 0, y: 0, width: width, height: height)

        let request = VNDetectFaceRectanglesRequest()
        try? VNImageRequestHandler(cgImage: cgImage, orientation: .up).perform([request])
        if let face = request.results?.max(by: { $0.boundingBox.width < $1.boundingBox.width }) {
            // Vision's box is normalized with the origin at the bottom left.
            let box = face.boundingBox
            let faceWidth = box.width * width
            let center = CGPoint(x: box.midX * width, y: (1 - box.midY) * height)
            // YouCam wants the face to fill 60 to 80% of the width, measured more tightly than
            // Vision's box. Aim for about 78% of Vision's box so YouCam sees ~70%.
            var cropWidth = faceWidth / 0.78
            cropWidth = min(width, cropWidth)
            let cropHeight = min(height, cropWidth * 4 / 3)
            var x = center.x - cropWidth / 2
            var y = center.y - cropHeight / 2
            x = min(max(0, x), width - cropWidth)
            y = min(max(0, y), height - cropHeight)
            crop = CGRect(x: x, y: y, width: cropWidth, height: cropHeight).integral
        }

        guard let cropped = cgImage.cropping(to: crop) else { return nil }
        #if DEBUG
        print("Analysis photo: \(Int(width))x\(Int(height)) -> crop \(Int(crop.width))x\(Int(crop.height))", crop.width >= 1080 ? "(HD)" : "(standard)")
        #endif
        let longest = max(crop.width, crop.height)
        guard longest > 2560 else { return UIImage(cgImage: cropped) }

        let scale = 2560 / longest
        let size = CGSize(width: (crop.width * scale).rounded(), height: (crop.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIImage(cgImage: cropped).draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
