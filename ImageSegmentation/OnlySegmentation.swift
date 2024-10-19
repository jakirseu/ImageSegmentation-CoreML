import SwiftUI
import CoreML
import Vision

struct OnlySegmentation: View {
    
    @State private var inputImage: UIImage? = UIImage(named: "cat")
    @State private var segmentedMask: UIImage? = nil
    var body: some View {
        
        VStack {
            if let inputImage = inputImage {
                Image(uiImage: inputImage)
                    .resizable()
                    .scaledToFit()
                
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
            }
            
        }
        .padding()
    }
    
    func applyImageSegmentation() {
        do {
            let modelConfiguration = MLModelConfiguration()
            // load model
            let model = try VNCoreMLModel(for: DeepLabV3(configuration: modelConfiguration).model)
            
            let request = VNCoreMLRequest(model: model) { request, error in
                if let results = request.results as? [VNCoreMLFeatureValueObservation],
                   let multiArray = results.first?.featureValue.multiArrayValue {
                    
                    // convert array to image
                    self.segmentedMask = self.multiArrayToMaskImage(multiArray)
              
                } else {
                    print("No valid segmentation results")

                }
            }
            
            request.imageCropAndScaleOption = .scaleFill
            
            if let cgImage = inputImage?.cgImage {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            }
        } catch {
            print("Error: \(error.localizedDescription)")

        }
    }
    
    func multiArrayToMaskImage(_ multiArray: MLMultiArray) -> UIImage? {
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
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
