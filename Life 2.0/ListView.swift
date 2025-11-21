import Foundation
import SwiftUI
import SwiftData

// MARK: - Row with animated gauge
struct EventRowView: View {
    
    let item: Life2Event
    
    @State private var animatedScore: Double = 0
    @State private var hasAnimated = false
    
    var body: some View {
        
        HStack {
            
            // --------------------------------
            // Event Icon
            // --------------------------------
            Image(systemName: item.icon)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .padding(0)
            
            Spacer(minLength: 20)
            
            // --------------------------------
            // Activity Name and Progress
            // --------------------------------
            VStack(alignment: .leading) {
                
                // --------------------------------
                // Activity Name
                Text(item.name)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // --------------------------------
                // Activity Progress
                Gauge(value: animatedScore, in: 0...100) {
                    EmptyView()                                 // no label
                } currentValueLabel: {
                    EmptyView()                                 // we'll draw our own text
                }
                .gaugeStyle(.automatic)
                .tint(.green)                                   // green fill
                .frame(maxWidth: .infinity)
                
                // --------------------------------
                // Draw Text on top of the guage
                .overlay {                          // center the score text on top
                    Text("\(Int(animatedScore))%")
                        .monospacedDigit()
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
        }
        .onAppear {
            
            // --------------------------------
            // Only animate once per row
            guard !hasAnimated else { return }
            hasAnimated = true
            
            animatedScore = 0
            withAnimation(.easeOut(duration: 0.8)) {
                animatedScore = item.score
            }
        }
    }
}

// MARK: - ListView
struct ListView: View {
    
    @Query var Life2Events: [Life2Event]
    
    private var groupedByCategory: [String: [Life2Event]] {
        Dictionary(grouping: Life2Events, by: { $0.category })
    }
    
    var body: some View {
        
        NavigationStack{
            
            Group {
                
                // --------------------------------
                // Render the list
                List {
                    
                    // --------------------------------
                    // Group by Category
                    ForEach(groupedByCategory.keys.sorted(), id: \.self) { category in
                        
                        // --------------------------------
                        // Add a Section Header for each Category
                        Section(header: Text(category)) {
                            
                            // --------------------------------
                            // Render the items under each Category
                            ForEach(groupedByCategory[category]!) { item in
                                
                                // --------------------------------
                                // Use a Custom Row that animates the graph
                                EventRowView(item: item)   // ← use animated row
                            }
                            .padding(0)
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

// MARK: - Preview code for Canvas
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
    
    ListView()   // ← make sure this matches the struct name
        .modelContainer(previewContainer)
}
