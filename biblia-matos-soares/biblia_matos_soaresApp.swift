import SwiftUI
import SwiftData

@main
struct biblia_matos_soaresApp: App {
    // Criação do container de dados persistente
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BibleVerse.self,
            VerseNote.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("❌ Erro ao criar o banco de dados: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContext(sharedModelContainer.mainContext) // injeta o contexto
                .task {
                    let context = sharedModelContainer.mainContext
                    let importer = BibleImporter(context: context)

                    // >>> AQUI: Adicione a verificação condicional <<<
                    if !(await importer.hasImportedData()) {
                        print("📖 Iniciando importação da Bíblia (primeira vez)...")
                        await importer.importBible()
                    } else {
                        print("✅ Bíblia já importada. Não é necessário importar novamente.")
                        print("Total de versículos: \(await importer.countVerses())")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
