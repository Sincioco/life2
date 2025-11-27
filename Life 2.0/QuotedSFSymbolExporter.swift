import SwiftUI

struct SymbolFormatterView: View {

    @State private var inputSymbols: String = ""
    @State private var outputSymbols: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // Input
                Text("Input Symbols")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $inputSymbols)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .frame(minHeight: 200)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray))

                // Button
                Button(action: processSymbols) {
                    Text("Convert → Quoted Output")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                // Output
                Text("Output")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $outputSymbols)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .frame(minHeight: 200)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray))

                Spacer()
            }
            .padding()
            .navigationTitle("SF Symbol Formatter")
        }
    }

    // MARK: - Logic

    private func processSymbols() {
        let lines = inputSymbols
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // De-dupe + alphabetical
        let cleaned = Array(Set(lines)).sorted()

        let quoted = cleaned.map { "\"\($0)\"," }
            .joined(separator: "\n")

        outputSymbols = quoted

        // Also output to console
        print("\n---- OUTPUT ----\n")
        print(quoted)
    }
}
