import Foundation
import SwiftUI

struct GridTest: View {
    
    let icons = ["star.fill"]
    
    var body: some View {
        
        ScrollView(.vertical) {
            
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let scrollHeight = geometry.size.height      // ScrollView content height
                let side = min(totalWidth, scrollHeight)     // Max square that fits
                
                let columns = [
                    GridItem(.fixed(side), spacing: 0)
                ]
                
                VStack {
                    Spacer()    // push down
                    
                    HStack {
                        Spacer() // center horizontally
                        
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(icons, id: \.self) { symbol in
                                ZStack {
                                    
                                    Image(systemName: symbol)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: side * 0.9, height: side * 0.9)
                                }
                                .frame(width: side, height: side)  // <— cell size
                                .overlay(alignment: .topLeading) {
                                    Text("31")
                                        .font(.headline)
                                        .padding(8)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()    // push up
                }
                .frame(width: totalWidth, height: scrollHeight)
                .background(.yellow.opacity(0.8))
            }
            .frame(height: 100)    // ScrollView visible height
        }
        .frame(width: 100, height: 100)
        .background(.green)
    }
}

#Preview {
    GridTest()
}
