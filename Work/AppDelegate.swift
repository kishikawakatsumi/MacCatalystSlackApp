import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var appKitSupport: NSObject?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let pluginPath = Bundle.main.builtInPlugInsPath!.appending("/AppKitSupport.bundle")
        let bundle = Bundle(path: pluginPath)!
        bundle.load()

        let `class` = bundle.principalClass as! NSObject.Type
        appKitSupport = `class`.init()
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if options.userActivities.first?.activityType == "panel" {
            let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
            configuration.delegateClass = ImagePanelWindowSceneDelegate.self
            return configuration
        } else {
            return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }
    }
}
