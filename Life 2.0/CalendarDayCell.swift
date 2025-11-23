import Foundation
import SwiftUI

struct CalendarDayCell: View {
    
    var day: Date = Date()
    var cellWidth: CGFloat = 300
    var cellHeight: CGFloat = 300
    
    
    var icons = [
        "star.fill"
        , "house"
        , "pencil"
    ]
    
    var body: some View {
        
        let dayString = String(Calendar.current.component(.day, from: day))
        
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
                                        //.border(Color.black)
                                        //.tint(.blue)
                                        .foregroundColor(.blue)     // <— solid blue
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
            //.background(.yellow.opacity(0.8))
            .overlay(alignment: .topLeading) {
                // This is the Day Text
                Text("\(dayString)")
                    .font(.headline)
                    .padding(8)
                    .foregroundStyle(.primary)
                    .shadow(color: invertedPrimaryColor().opacity(0.6), radius: 2)
                    
            }
            .frame(height: geometry.size.height)    // ScrollView visible height
        }
        
        .frame(width: cellWidth, height: cellHeight)
        //.background(.green)
    }
    
    func invertedPrimaryColor() -> Color {
        let ui = UIColor.label     // dynamic primary color

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        ui.getRed(&r, green: &g, blue: &b, alpha: &a)

        return Color(
            red: 1 - r,
            green: 1 - g,
            blue: 1 - b,
            opacity: Double(a)
        )
    }
}

#Preview {
    CalendarDayCell()
}
