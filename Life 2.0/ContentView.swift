//
//  ContentView.swift
//  Life 2.0
//
//  Created by Sin on 11/19/25.
//

import SwiftUI

struct Event: Identifiable {
    let id = UUID()
    var name: String
    var imageName: String
    var score: Double
}

struct ContentView: View {
    @State private var selectedPerson: Event? = nil
    @State private var showActions: Bool = false
    @State private var showDetails: Bool = false
    @State private var showAddFromToolbar: Bool = false
    @State private var searchText: String = ""
    @State private var showFilter: Bool = false
    
    let people: [Event] = [
        Event(name: "Walk the Dog", imageName: "pawprint.fill", score: 73),
        Event(name: "Meditate for 5 Minutes", imageName: "figure.mind.and.body", score: 95),
        Event(name: "Run / Exercise", imageName: "figure.run", score: 67)
    ]
    
    var filteredPeople: [Event] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return people }
        return people.filter { person in
            person.name.localizedCaseInsensitiveContains(query)
            || String(Int(person.score)).contains(query)
        }
    }
    
    var body: some View {
        
        TabView {
            Tab("Summary", systemImage: "list.bullet.rectangle") {
                NavigationStack {
                    Group {
                        if filteredPeople.isEmpty && !searchText.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            List(filteredPeople) { item in
                                VStack {
                                    HStack {
                                        Image(systemName: item.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(.blue)
                                            .frame(width: 40, height: 40)
                                            .padding(0)
                                        Spacer(minLength: 20)
                                        VStack(alignment: .leading) {
                                            
                                            Text(item.name)
                                                .font(.body)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Gauge(value: item.score, in: 0...100) {
                                                Text("Score")
                                                    .fontWeight(.regular)
                                            } currentValueLabel: {
                                                Text("\(Int(item.score))%")
                                                    .monospacedDigit()
                                                    .fontWeight(.regular)
                                            }
                                            .gaugeStyle(.accessoryLinear)
                                            .tint(.blue)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .padding(0)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPerson = item
                                    showActions = true
                                }
                                .contextMenu {
                                    Button("Completed") {
                                        // TODO: Handle completion for item
                                    }
                                    Button("Details") {
                                        selectedPerson = item
                                        showDetails = true
                                    }
                                    Button("Delete", role: .destructive) {
                                        // TODO: Handle delete for item
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .searchable(text: $searchText)
                    .searchSuggestions {
                        ForEach(people.prefix(5)) { item in
                            Text(item.name)
                                .searchCompletion(item.name)
                        }
                    }
                    .navigationTitle("Summary")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showFilter = true
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                            .accessibilityLabel("Filter")
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showAddFromToolbar = true
                            } label: {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("Add Item")
                        }
                    }
                    .sheet(isPresented: $showDetails) {
                        if let person = selectedPerson {
                            PersonDetailView(person: person)
                        }
                    }
                    .sheet(isPresented: $showAddFromToolbar) {
                        // Placeholder Add content; replace with your add flow
                        VStack(spacing: 16) {
                            Image(systemName: "plus.circle")
                                .font(.largeTitle)
                            Text("Add new item")
                                .font(.headline)
                            Button("Close") { showAddFromToolbar = false }
                        }
                        .padding()
                    }
                    .sheet(isPresented: $showFilter) {
                        NavigationStack {
                            Form {
                                Section("Filters") {
                                    Toggle("Completed only", isOn: .constant(false))
                                    Toggle("High score (>= 80)", isOn: .constant(false))
                                }
                            }
                            .navigationTitle("Filter")
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") { showFilter = false }
                                }
                            }
                        }
                    }
                }
            }
            Tab("Calendar", systemImage: "calendar") {
            }
            Tab("Help", systemImage: "questionmark.circle") {
            }
            Tab("Options", systemImage: "line.3.horizontal") {
            }
        }
    }
}

struct PersonDetailView: View {
    let person: Event
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: person.imageName)
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .padding()
                .background(Circle().fill(.ultraThinMaterial))
            
            Text(person.name)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Score")
                    .font(.subheadline)
                    .fontWeight(.regular)
                Gauge(value: person.score, in: 0...100) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(Int(person.score))")
                        .monospacedDigit()
                        .fontWeight(.regular)
                }
                .gaugeStyle(.accessoryLinear)
                .tint(.blue)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}

