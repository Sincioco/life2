//
//  SwiftUIViewTest.swift
//  Life 2.0
//
//  Created by Sin on 11/21/25.
//  https://www.youtube.com/watch?v=vfUalXtwth0


import SwiftUI
extension Color {
    static var random: Color {
        Color(
            red:   .random(in: 0...1),
            green: .random(in: 0...1),
            blue:  .random(in: 0...1)
        )
    }
}

struct MockData {
    static var colors: [Color] {
        var array: [Color] = []
        for _ in 0..<42 {array.append(Color.random)}
        return array
    }
}
struct SwiftUIGridView: View {
    var body: some View {
        
        let columns = Array(repeating: GridItem(.fixed(100), spacing: 0 ), count: 7)
        NavigationStack {
            
            ScrollView([.horizontal, .vertical]) {
                
                // Declare the grid and its columns
                LazyVGrid(columns: columns, spacing: 0) {
                    
                    // Render the contents of the grid
                    ForEach(MockData.colors, id: \.self) { color in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color)
                        //.stroke(style: StrokeStyle(lineWidth: 1))
                            .frame(height: 100)
                    }
                    
                }
            }
            
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    SwiftUIGridView()
}
