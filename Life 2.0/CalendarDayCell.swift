import Foundation
import SwiftUI

struct CalendarDayCell: View {
    
    var day: Date = Date()
    var cellWidth: CGFloat = 63
    var cellHeight: CGFloat = 63
    
    //    var cellWidth: CGFloat = 119
    //    var cellHeight: CGFloat = 119
    
    var icons = [
        "figure.run",
        "house",
        "pencil",
        "star",
        "eraser"
    ]
    
    var cellDebug: Bool = true
    
    var body: some View {
        
        let dayString = String(Calendar.current.component(.day, from: day))
        //let dayString = "16"
        
        GeometryReader { geometry in
            
            let totalWidth = geometry.size.width
            let scrollHeight = geometry.size.height      // ScrollView content height
            let side = min(totalWidth, scrollHeight - 20)     // Max square that fits
            let iconCount = icons.count
            
            let columns = [
                GridItem(.fixed(side), spacing: 0)
            ]
            
            // The Group is the Cell Container
            Group {
                
                if (iconCount == 1) {
                    
                    //VStack {
                    Image(systemName: icons[0])
                        .resizable()
                        .scaledToFit()
                        .frame(width: side * 0.9, height: side * 0.9)
                        .foregroundColor(.blue)
                        .border(cellDebug == true ? Color.red : Color.clear)
                        .frame(width: side, height: side)
                        .padding(.top, 26)
                    
                } else if (iconCount == 2) {
                    
                    HStack(spacing: 2) {
                        Image(systemName: icons[0])
                            .resizable()
                            .scaledToFit()
                            .frame(width: side * 0.5, height: side * 0.5)
                            .foregroundColor(.blue)
                            .border(cellDebug == true ? Color.blue : Color.clear)
                        Image(systemName: icons[1])
                            .resizable()
                            .scaledToFit()
                            .frame(width: side * 0.6, height: side * 0.5)
                            .foregroundColor(.blue)
                            .border(cellDebug == true ? Color.red : Color.clear)
                        
                    }
                    .frame(width: side, height: side)
                    .padding(.top, 26)
                    
                    
                    
                } else if (iconCount == 3 || iconCount == 4) {
                    
                    VStack (spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: icons[0])
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(.blue)
                                .border(cellDebug == true ? Color.blue : Color.clear)
                            Image(systemName: icons[1])
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(.blue)
                                .border(cellDebug == true ? Color.red : Color.clear)
                        }
                        .padding(.top, 26)
                        
                        if (iconCount == 4) {
                            HStack(spacing: 6) {
                                Image(systemName: icons[2])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: side * 0.4, height: side * 0.4)
                                    .foregroundColor(.blue)
                                    .border(cellDebug == true ? Color.blue : Color.clear)
                                Image(systemName: icons[3])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: side * 0.4, height: side * 0.4)
                                    .foregroundColor(.blue)
                                    .border(cellDebug == true ? Color.red : Color.clear)
                            }
                        }
                        
                    }
                    
                } else if (iconCount == 5) {
                    
                    VStack (spacing: 0) {
                        HStack(spacing: 6) {
                            Color.clear
                                .frame(width: side * 0.4, height: side * 0.4)
                                .border(cellDebug ? .blue : .clear)
                            Image(systemName: icons[0])
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(.blue)
                                .border(cellDebug == true ? Color.red : Color.clear)
                        }
                        .padding(.top, 6)
                        
                        
                        HStack(spacing: 6) {
                            Image(systemName: icons[1])
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(.blue)
                                .border(cellDebug == true ? Color.blue : Color.clear)
                            Image(systemName: icons[2])
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(.blue)
                                .border(cellDebug == true ? Color.red : Color.clear)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: icons[3])
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(.blue)
                                .border(cellDebug == true ? Color.blue : Color.clear)
                            Image(systemName: icons[4])
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(.blue)
                                .border(cellDebug == true ? Color.red : Color.clear)
                        }
                    }
                } else {
                    
                    // Where the icons show up (scrollable incase there are more icons
                    ScrollView(.vertical) {
                        
                        // Center's the grid / icon container
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(icons, id: \.self) { symbol in
                                VStack {
                                    Image(systemName: symbol)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: side * 0.9, height: side * 0.7)
                                        .foregroundColor(.blue)     // <— solid blue
                                }
                                .frame(width: side, height: side)
                            }
                        }
                    }
                    .frame(height: cellHeight - 20)
                    .padding(.top, 26)
                }
            }
            
            
            .frame(width: totalWidth, height: scrollHeight)
            .background(cellDebug == true ? .yellow.opacity(0.8) : Color.clear)
            .overlay(alignment: .topLeading) {
                // This is the Day Text
                Text("\(dayString)")
                //Text("\(dayString) \(iconCount)")
                    .font(.headline)
                    .padding(8)
                    .foregroundStyle(.primary)
                //.shadow(color: invertedPrimaryColor().opacity(0.6), radius: 2)
                
            }
            .frame(height: geometry.size.height)    // ScrollView visible height
        }
        
        .frame(width: cellWidth, height: cellHeight)
        .background(cellDebug == true ? Color.green : Color.clear)
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
