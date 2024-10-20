 

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack{
            NavigationLink("Only Segmentation", destination: OnlySegmentation())
            
            NavigationLink("Get Segmented Image", destination: SegmentedImage())
            
            NavigationLink("Get Segmented Image", destination: BackgroundChange())
            
        }
    }
}

#Preview {
    ContentView()
}
