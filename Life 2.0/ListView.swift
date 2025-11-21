//
//  MainView2.swift
//  Life 2.0
//
//  Created by Sin on 11/22/25.
//

import Foundation
import SwiftUI
import SwiftData

struct ListView: View {
    
    @Query var Life2Events: [Life2Event]
    
    private var groupedByCategory: [String: [Life2Event]] {
        Dictionary(grouping: Life2Events, by: { $0.category })
    }
    
    var body: some View {
        NavigationStack{
            Group {
                List {
                    
                    ForEach(groupedByCategory.keys.sorted(), id: \.self) { category in
                        
                        Section(header: Text(category)) {
                            
                            ForEach(groupedByCategory[category]!) { item in
                                
                                HStack {
                                    
                                    // Event Icon
                                    Image(systemName: item.icon)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(.blue)
                                        .frame(width: 40, height: 40)
                                        .padding(0)
                                    
                                    Spacer(minLength: 20)
                                    
                                    // Event Name and Progress Bar
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Gauge(value: item.score, in: 0...100) {
                                            EmptyView()   // no label
                                        } currentValueLabel: {
                                            EmptyView()   // we'll draw our own text
                                        }
                                        .gaugeStyle(.automatic)
                                        .tint(.green)                       // green fill
                                        .frame(maxWidth: .infinity)
                                        //.frame(height: 24)                  // a bit taller
                                        .overlay {                          // center the score text on top
                                            Text("\(Int(item.score))%")
                                                .monospacedDigit()
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                //.foregroundStyle(.white)
                                            
                                        }
                                    }
                                    
                                }
                            }
                            .padding(0)
                            //.listRowSeparator(.hidden)
                        }
                        .contentShape(Rectangle())
                    }
                }
                .listRowSeparator(.hidden)
            }
            .navigationTitle("Activities")
        }
    }
}



#Preview {
    
    let previewContainer: ModelContainer = {
        let schema = Schema([Life2Event.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: config)
        
        // Insert test data
        for event in Life2Event.sampleData {
            container.mainContext.insert(event)
        }
        
        return container
    }()
    
    MainView2()
        .modelContainer(previewContainer)
}
