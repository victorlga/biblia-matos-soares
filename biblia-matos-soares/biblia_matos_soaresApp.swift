import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - Import Status Observable
@MainActor
class ImportStatus: ObservableObject {
    @Published var isImportComplete: Bool = false
}

// MARK: - AppDelegate for Firebase + Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("🔔 Notification permission granted: \(granted)")
        }
        application.registerForRemoteNotifications()
        
        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // Get APNs token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Handle FCM token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM token: \(String(describing: fcmToken))")
    }
    
    // Foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - Main App
@main
struct biblia_matos_soaresApp: App {
    // Register AppDelegate for Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Import status to signal when Bible data is ready
    @StateObject private var importStatus = ImportStatus()

    // SwiftData container with migration support and resilient fallback
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BibleVerse.self,
            VerseNote.self,
            ReadingProgress.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Try creating with staged migration plan first
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: BibleMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            print("⚠️ Staged migration failed: \(error)")
            print("⚠️ Attempting fallback: lightweight migration without migration plan...")
        }

        // Fallback 1: Try without migration plan (lightweight migration)
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            print("⚠️ Lightweight migration also failed: \(error)")
            print("⚠️ Deleting existing store and recreating...")
        }

        // Fallback 2: Delete the store and recreate from scratch.
        // Bible data will be re-imported from the bundled JSON on next launch.
        // User notes and highlights will be lost.
        let storeURL = modelConfiguration.url
        let storePaths = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm"),
        ]
        for path in storePaths {
            try? FileManager.default.removeItem(at: path)
        }
        print("🗑️ Deleted existing store files at \(storeURL.path)")

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: BibleMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("❌ Error creating database after store reset: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContext(sharedModelContainer.mainContext)
                .environmentObject(importStatus)
                .task {
                    let context = sharedModelContainer.mainContext
                    let importer = BibleImporter(context: context)

                    if !(await importer.hasImportedData()) {
                        print("📖 Importing Bible for the first time…")
                        await importer.importBible()
                    } else {
                        print("✅ Bible already imported.")
                        print("Total verses: \(await importer.countVerses())")
                    }

                    // Signal that import is complete (or data was already present)
                    importStatus.isImportComplete = true
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
