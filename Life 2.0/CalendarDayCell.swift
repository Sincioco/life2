// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                   Life 2.0 - Calendar View Day Cell
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 23, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  A view to a cell to day in the Calendar view.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftUI

struct CalendarDayCell: View {

    var day: Date = Date()
    /// Simple orientation helper (no UIScreen.main)
        private var isLandscape: Bool {
            UIDevice.current.orientation.isLandscape
        }

        private var isPad: Bool {
            UIDevice.current.userInterfaceIdiom == .pad
        }

        private var cellWidth: CGFloat {
            if isPad {
                return isLandscape ? 159 : 104  // iPad
            } else {
                return isLandscape ? 119 : 63   // iPhone
            }
        }

        private var cellHeight: CGFloat {
            if isPad {
                return isLandscape ? 159 : 104  // iPad
            } else {
                return isLandscape ? 119 : 63   // iPhone
            }
        }
    var icons = [
        "basketball.fill",
        "figure.run",
        "house",
        "pencil",
        "star",
        "eraser",
        "globe.americas"
    ]
    var adjacentCell: Bool = false
    var cellDebug: Bool = true
    /// Closure so the parent (CalendarView) can decide the color for each icon
    var colorForIcon: (String) -> Color = { _ in .blue }

    var body: some View {

        let dayString = String(Calendar.current.component(.day, from: day))
        @State var additionalScale1: CGFloat = 0.0
        
        GeometryReader { geometry in

            let totalWidth = geometry.size.width
            let scrollHeight = geometry.size.height      // ScrollView content height
            let side = min(totalWidth, scrollHeight - 20)     // Max square that fits
            let iconCount = icons.count

            // The Group is the Cell Container
            Group {

                if (iconCount == 1) {

                    let icon = icons[0]
                    let isAsset = UIImage(named: icon) != nil     // detect if image exists in Assets
                    let img = isAsset ? Image(icon) : Image(systemName: icon)
                
                    img
                        .resizable()
                        .scaledToFit()
                        .frame(width: side * 0.75, height: side * 0.75)
                        .foregroundColor(colorForIcon(icon))
                        .border(cellDebug ? .red : .clear)
                        .frame(width: side, height: side)
                        .padding(.top, 26)
                        .opacity(adjacentCell ? 0.5 : 1.0)

                } else if (iconCount == 2) {

                    HStack(spacing: 2) {
                        let icon = icons[0]
                        let isAsset = UIImage(named: icon) != nil     // detect if image exists in Assets
                        let img = isAsset ? Image(icon) : Image(systemName: icon)
                    
                        img
                            .resizable()
                            .scaledToFit()
                            .frame(width: side * 0.5, height: side * 0.5)
                            .foregroundColor(colorForIcon(icons[0]))
                            .border(cellDebug == true ? Color.blue : Color.clear)
                            .opacity(adjacentCell ? 0.5 : 1.0)

                        let icon1 = icons[1]
                        let isAsset1 = UIImage(named: icon1) != nil     // detect if image exists in Assets
                        let img1 = isAsset1 ? Image(icon1) : Image(systemName: icon1)
                    
                        img1
                            .resizable()
                            .scaledToFit()
                            .frame(width: side * 0.4, height: side * 0.5)
                            .foregroundColor(colorForIcon(icons[1]))
                            .border(cellDebug == true ? Color.red : Color.clear)
                            .opacity(adjacentCell ? 0.5 : 1.0)

                    }
                    .frame(width: side, height: side)
                    .padding(.top, 26)

                } else if (iconCount == 3 || iconCount == 4) {

                    VStack (spacing: 0) {
                        HStack(spacing: 6) {
                            let icon = icons[0]
                            let isAsset = UIImage(named: icon) != nil     // detect if image exists in Assets
                            let img = isAsset ? Image(icon) : Image(systemName: icon)
                        
                            img
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(colorForIcon(icons[0]))
                                .border(cellDebug == true ? Color.blue : Color.clear)
                                .opacity(adjacentCell ? 0.5 : 1.0)

                            let icon1 = icons[1]
                            let isAsset1 = UIImage(named: icon1) != nil     // detect if image exists in Assets
                            let img1 = isAsset1 ? Image(icon1) : Image(systemName: icon1)
                        
                            img1
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(colorForIcon(icons[1]))
                                .border(cellDebug == true ? Color.red : Color.clear)
                                .opacity(adjacentCell ? 0.5 : 1.0)
                        }
                        .padding(.top, 26)

                        if (iconCount == 4) {
                            HStack(spacing: 6) {
                                let icon2 = icons[2]
                                let isAsset2 = UIImage(named: icon2) != nil     // detect if image exists in Assets
                                let img2 = isAsset2 ? Image(icon2) : Image(systemName: icon2)
                            
                                img2
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: side * 0.4, height: side * 0.4)
                                    .foregroundColor(colorForIcon(icons[2]))
                                    .border(cellDebug == true ? Color.blue : Color.clear)
                                    .opacity(adjacentCell ? 0.5 : 1.0)

                                let icon3 = icons[3]
                                let isAsset3 = UIImage(named: icon3) != nil     // detect if image exists in Assets
                                let img3 = isAsset3 ? Image(icon3) : Image(systemName: icon3)
                            
                                img3
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: side * 0.4, height: side * 0.4)
                                    .foregroundColor(colorForIcon(icons[3]))
                                    .border(cellDebug == true ? Color.red : Color.clear)
                                    .opacity(adjacentCell ? 0.5 : 1.0)
                            }
                        }

                    }

                } else if (iconCount == 5) {

                    VStack (spacing: 0) {
                        HStack(spacing: 6) {
                            Color.clear
                                .frame(width: side * 0.4, height: side * 0.4)
                                .border(cellDebug ? .blue : .clear)
                            
                            let icon = icons[0]
                            let isAsset = UIImage(named: icon) != nil     // detect if image exists in Assets
                            let img = isAsset ? Image(icon) : Image(systemName: icon)
                        
                            img
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(colorForIcon(icons[0]))
                                .border(cellDebug == true ? Color.red : Color.clear)
                                .opacity(adjacentCell ? 0.5 : 1.0)
                        }
                        .padding(.top, 6)


                        HStack(spacing: 6) {
                            let icon1 = icons[1]
                            let isAsset1 = UIImage(named: icon1) != nil     // detect if image exists in Assets
                            let img1 = isAsset1 ? Image(icon1) : Image(systemName: icon1)
                        
                            img1
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(colorForIcon(icons[1]))
                                .border(cellDebug == true ? Color.blue : Color.clear)
                                .opacity(adjacentCell ? 0.5 : 1.0)

                            let icon2 = icons[2]
                            let isAsset2 = UIImage(named: icon2) != nil     // detect if image exists in Assets
                            let img2 = isAsset2 ? Image(icon2) : Image(systemName: icon2)
                        
                            img2
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(colorForIcon(icons[2]))
                                .border(cellDebug == true ? Color.red : Color.clear)
                                .opacity(adjacentCell ? 0.5 : 1.0)
                        }

                        HStack(spacing: 6) {
                            let icon3 = icons[3]
                            let isAsset3 = UIImage(named: icon3) != nil     // detect if image exists in Assets
                            let img3 = isAsset3 ? Image(icon3) : Image(systemName: icon3)
                        
                            img3
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(colorForIcon(icons[3]))
                                .border(cellDebug == true ? Color.blue : Color.clear)
                                .opacity(adjacentCell ? 0.5 : 1.0)

                            let icon4 = icons[4]
                            let isAsset4 = UIImage(named: icon4) != nil     // detect if image exists in Assets
                            let img4 = isAsset4 ? Image(icon4) : Image(systemName: icon4)
                        
                            img4
                                .resizable()
                                .scaledToFit()
                                .frame(width: side * 0.4, height: side * 0.4)
                                .foregroundColor(colorForIcon(icons[4]))
                                .border(cellDebug == true ? Color.red : Color.clear)
                                .opacity(adjacentCell ? 0.5 : 1.0)
                        }
                    }
                } else {

                    // 6 or more icons - create a view that is scrollable so we can see more icons
                    ScrollView(.vertical, showsIndicators: true) {

                        // 2 columns so you see 2 images per row
                        let columns = [
                            GridItem(.flexible(), spacing: 0),
                            GridItem(.flexible(), spacing: 0)
                        ]

                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(icons, id: \.self) { symbol in
                                HStack(spacing: 0) {
                                    let icon = symbol
                                    let isAsset = UIImage(named: icon) != nil     // detect if image exists in Assets
                                    let img = isAsset ? Image(icon) : Image(systemName: icon)
                                
                                    img
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: side * 0.4, height: side * 0.4)
                                        .foregroundColor(colorForIcon(symbol))     // solid blue -> activity color
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(.horizontal, 0)
                                        .opacity(adjacentCell ? 0.5 : 1.0)
//                                        .border(.red);
                                }
                                .frame(height: side * 0.45) // tweak as needed for row height
                            }
                        }
                    }
                    .frame(width: cellWidth - 10, height: cellHeight - 20)
                    .padding(.top, 30)
                }
            }

            .frame(width: totalWidth, height: scrollHeight)
            .background(cellDebug == true ? .yellow.opacity(0.8) : Color.clear)
            .overlay(alignment: .topLeading) {
                // This is the Day Text
                Text("\(dayString)")
                    .font(.headline)
                    .padding(8)
                    .foregroundStyle(adjacentCell ? .secondary : .primary)
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
