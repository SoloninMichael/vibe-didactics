import CoreImage
import Foundation

/// Draws a QR code in the terminal with half-block characters (two modules per row).
enum TerminalQR {
    static func render(_ text: String) -> String? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel")
        guard let image = filter.outputImage,
              let cgImage = CIContext().createCGImage(image, from: image.extent) else { return nil }

        let size = cgImage.width
        var pixels = [UInt8](repeating: 255, count: size * size)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.interpolationQuality = .none
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
            return true
        }
        guard drawn else { return nil }

        let quiet = 2
        let full = size + quiet * 2
        func dark(_ x: Int, _ y: Int) -> Bool {
            let px = x - quiet, py = y - quiet
            guard px >= 0, py >= 0, px < size, py < size else { return false }
            return pixels[py * size + px] < 128
        }

        var lines: [String] = []
        for y in stride(from: 0, to: full, by: 2) {
            var row = ""
            for x in 0..<full {
                switch (dark(x, y), dark(x, y + 1)) {
                case (true, true): row += "█"
                case (true, false): row += "▀"
                case (false, true): row += "▄"
                case (false, false): row += " "
                }
            }
            // Black modules on a white background so phone cameras read it on dark terminals too.
            lines.append("  " + (Console.isTerminal ? "\u{1B}[30;107m\(row)\u{1B}[0m" : row))
        }
        return lines.joined(separator: "\n")
    }
}
