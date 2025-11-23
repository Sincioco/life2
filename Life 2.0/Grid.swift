import Foundation
import SwiftUI

struct GridTest: View {
    
    let icons = ["star.fill"]
    
    var body: some View {
        
        
        GeometryReader { geometry in
            
            let totalWidth = geometry.size.width
            let scrollHeight = geometry.size.height      // ScrollView content height
            let side = min(totalWidth, scrollHeight)     // Max square that fits
            
            let columns = [
                GridItem(.fixed(side), spacing: 0)
            ]
            
            // The Group is the Cell Container
            Group {
                
                // Where the icons show up
                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(icons, id: \.self) { symbol in
                            ZStack {
                                
                                Image(systemName: symbol)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: side * 0.9, height: side * 0.9)
                            }
                            .frame(width: side, height: side)  // <— cell size
                            
                        }
                    }
                }
            }
            .frame(width: totalWidth, height: scrollHeight)
            .background(.yellow.opacity(0.8))
            .overlay(alignment: .topLeading) {
                // This is the Day Text
                Text("33")
                    .font(.headline)
                    .padding(8)
                    .foregroundStyle(.primary)
            }
        }
        .frame(height: 100)    // ScrollView visible height
        .frame(width: 200, height: 200)
        .background(.green)
    }
}

#Preview {
    GridTest()
}
