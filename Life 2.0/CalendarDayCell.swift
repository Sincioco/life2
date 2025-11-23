import Foundation
import SwiftUI

struct CalendarDayCell: View {
    
    let icons = [
        "star.fill"
        , "house"
        , "pencil"
    ]
    
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
                
                // Where the icons show up (scrollable incase there are more icons
                ScrollView(.vertical) {

                    //VStack {
                        //Spacer()   // push down
                        
                        // Center's the grid / icon container
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(icons, id: \.self) { symbol in
                                VStack {
                                    Image(systemName: symbol)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: side * 0.9, height: side * 0.9)
                                        .border(Color.black)
                                }
                                .frame(width: side, height: side)
                            }
                        }

                        //Spacer()   // push up
                    //}
                    //.frame(height: scrollHeight)    // <- critical: fill the ScrollView’s height
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
                    //.foregroundStyle(.white)
                    
            }
            .frame(height: geometry.size.height)    // ScrollView visible height
        }
        
        .frame(width: 300, height: 300)
        .background(.green)
    }
}

#Preview {
    CalendarDayCell()
}
