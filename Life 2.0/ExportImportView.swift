// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                      Life 2.0 - Export / Import View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 26, 2025                                                     For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Export and import all SwiftData models to/from a single JSON backup file.
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct ExportImportView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var activities: [Activity]

    @State private var isExporting: Bool = false
    @State private var exportDocument: BackupFileDocument? = nil

    @State private var isImporting: Bool = false
    @State private var pendingImportConfirmation: Bool = false
    @State private var showMustDeleteFirstAlert: Bool = false

    @State private var lastErrorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Export") {
                    Button {
                        exportBackup()
                    } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("Import") {
                    Text("Note:  Before you can import, please delete all existing data first by going to Options -> Delete All Activities.")
                    Button(role: .destructive) {
                        lastErrorMessage = nil
                        if !activities.isEmpty {
                            // Block import and tell user what to do
                            showMustDeleteFirstAlert = true
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                        } else {
                            // No activities, safe to proceed with normal import flow
                            pendingImportConfirmation = true
                        }
                    } label: {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                }

                if let message = lastErrorMessage {
                    Section("Status") {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Backup")
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: defaultBackupFilename()
            ) { result in
                switch result {
                case .success:
                    lastErrorMessage = "Export completed."
                    let success = UINotificationFeedbackGenerator()
                    success.notificationOccurred(.success)
                case .failure(let error):
                    lastErrorMessage = "Export failed: \(error.localizedDescription)"
                    let errorGen = UINotificationFeedbackGenerator()
                    errorGen.notificationOccurred(.error)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importBackup(from: url)
                case .failure(let error):
                    lastErrorMessage = "Import failed: \(error.localizedDescription)"
                    let errorGen = UINotificationFeedbackGenerator()
                    errorGen.notificationOccurred(.error)
                }
            }
            .alert(
                "Import Process",
                isPresented: $pendingImportConfirmation
            ) {
                Button("Import", role: .destructive) {
                    isImporting = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You will be prompted to select a backup file.  After the import process completes it may take a minute for the UI to reflects the changes.")
            }
            .alert(
                "Delete All Activities First",
                isPresented: $showMustDeleteFirstAlert
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You must first delete all activities before importing a backup by going to Options -> Delete All Activities.")
            }
        }
    }

    // MARK: - Export helpers

    private func defaultBackupFilename() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HHmm"
        let stamp = formatter.string(from: Date())
        return "\(stamp) - Backup"
    }

    private func exportBackup() {
        do {
            let categories = try Category.exportAll(in: modelContext)
            let activities = try Activity.exportAll(in: modelContext)
            let histories = try ActivityHistory.exportAll(in: modelContext)

            let payload = FullBackup(
                exportedAt: Date(),
                categories: categories,
                activities: activities,
                histories: histories
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(payload)
            exportDocument = BackupFileDocument(data: data)
            isExporting = true
        } catch {
            lastErrorMessage = "Unable to build backup: \(error.localizedDescription)"
            let errorGen = UINotificationFeedbackGenerator()
            errorGen.notificationOccurred(.error)
        }
    }

    // MARK: - Import helpers

    private func importBackup(from url: URL) {
        // This is REQUIRED for iCloud files
        guard url.startAccessingSecurityScopedResource() else {
            lastErrorMessage = "Unable to access the file due to iOS security restrictions."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let payload = try decoder.decode(FullBackup.self, from: data)

            try wipeAllExistingData()

            try Category.importAll(payload.categories, in: modelContext)
            try Activity.importAll(payload.activities, in: modelContext)
            try ActivityHistory.importAll(payload.histories, in: modelContext)

            NotificationCenter.default.post(name: .activityDidChange, object: nil)

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            lastErrorMessage = "Import completed successfully."

        } catch {
            lastErrorMessage = "Import failed: \(error.localizedDescription)"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }


    private func wipeAllExistingData() throws {
        let histories = try modelContext.fetch(FetchDescriptor<ActivityHistory>())
        for history in histories {
            modelContext.delete(history)
        }

        let activities = try modelContext.fetch(FetchDescriptor<Activity>())
        for activity in activities {
            modelContext.delete(activity)
        }

        let categories = try modelContext.fetch(FetchDescriptor<Category>())
        for category in categories {
            modelContext.delete(category)
        }

        //try modelContext.save()
    }
}

// MARK: - FileDocument + Payload

struct BackupFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

struct FullBackup: Codable {
    let exportedAt: Date
    let categories: [Category.CategoryBackup]
    let activities: [Activity.ActivityBackup]
    let histories: [ActivityHistory.HistoryBackup]
}
