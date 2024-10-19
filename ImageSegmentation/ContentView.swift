import SwiftUI
import CoreML
import Vision
import UIKit

struct ContentView: View {
    @State private var inputImage: UIImage? = UIImage(named: "cat")?.resizedImage(for: CGSize(width: 513, height: 513))
    @State private var segmentedMask: UIImage? = nil
    @State private var segmentedImage: UIImage? = nil
    var body: some View {
        ScrollView{
            VStack {
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                    
                } else {
                    Text("No image selected")
                        .padding()
                }
                
                
                Button(action: applyImageSegmentation) {
                    Text("Segment Image")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                if let segmentedMask = segmentedMask {
                    Image(uiImage: segmentedMask)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                }
                
                if let segmentedImage = segmentedImage {
                    Image(uiImage: segmentedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .border(Color.gray, width: 1)
                }
                
            }
            .padding()
        }
    }
    
    private func applyImageSegmentation() {
        do {
            let modelConfiguration = MLModelConfiguration()
            // load model
            let model = try VNCoreMLModel(for: DeepLabV3(configuration: modelConfiguration).model)
            
            let request = VNCoreMLRequest(model: model) { request, error in
                if let results = request.results as? [VNCoreMLFeatureValueObservation],
                   let multiArray = results.first?.featureValue.multiArrayValue {
                    // arry to image mask
                    let segementMask = self.multiArrayToMaskImage(multiArray)
                    // Ensure the segmented mask is resized to the original image size
                    if let maskImage = segementMask {
                        self.segmentedMask = maskImage.resizedImage(for: inputImage!.size)
                    }
                    
                } else {
                    print("No valid segmentation results")
                }
            }
            
            if let cgImage = inputImage?.cgImage {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            
        }
    }
    
    private func multiArrayToMaskImage(_ multiArray: MLMultiArray) -> UIImage? {
        let height = multiArray.shape[0].intValue
        let width = multiArray.shape[1].intValue
        
        var pixelBuffer = [UInt8](repeating: 0, count: width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let value = multiArray[[y as NSNumber, x as NSNumber]].int32Value
                // Convert to binary mask: 255 (white) for the object, 0 (black) for the background
                pixelBuffer[y * width + x] = value == 0 ? 0 : 255
            }
        }
        
        let context = CGContext(data: &pixelBuffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        if let cgImage = context?.makeImage() {
            // Resize the mask to match the input image size
            let maskImage = UIImage(cgImage: cgImage).resizedImage(for: inputImage!.size)
            // Get Segemented Image
            segmentedImage = applyMask(to: inputImage!, mask: maskImage!)
            
            return maskImage
        }
        
        
        return nil
    }
    
    private func applyMask(to inputImage: UIImage, mask: UIImage) -> UIImage? {
        guard let maskCGImage = mask.cgImage, let inputCGImage = inputImage.cgImage else { return nil }
        
        
        // add a bg image to your Assets.xcassets
        let bgImage = UIImage(named: "bg")?.resizedImage(for: CGSize(width: 513, height: 513))
        
        let input = CIImage(cgImage: inputCGImage)
        let mask = CIImage(cgImage: maskCGImage)
        let background = CIImage(cgImage: (bgImage?.cgImage!)!)
        
        
        if let compositeImage = CIFilter(name: "CIBlendWithMask", parameters: [
                                        kCIInputImageKey: input,
                                        kCIInputBackgroundImageKey:background,
                                        kCIInputMaskImageKey:mask])?.outputImage
        {
            
            
            let ciContext = CIContext(options: nil)

            let filteredImageRef = ciContext.createCGImage(compositeImage, from: compositeImage.extent)
            
            return UIImage(cgImage: filteredImageRef!)
            
        }
        
        return nil
    }
}


extension UIImage {
    func resizedImage(for targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
