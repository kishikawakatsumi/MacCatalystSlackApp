import UIKit

#if targetEnvironment(macCatalyst)
private let signInToolbarIdentifier =  NSToolbarItem.Identifier(rawValue: "SignIn")
private let searchToolbarIdentifier =  NSToolbarItem.Identifier(rawValue: "Search")
#endif

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let window = window else { return }

        #if targetEnvironment(macCatalyst)
        if let windowScene = scene as? UIWindowScene {
            if let titlebar = windowScene.titlebar {
                let toolbar = NSToolbar(identifier: "AppToolbar")

                toolbar.delegate = self
                titlebar.titleVisibility = .hidden

                titlebar.toolbar = toolbar
            }
        }
        #endif

        guard let splitViewController = window.rootViewController as? UISplitViewController else { return }
        splitViewController.primaryBackgroundStyle = .sidebar
        splitViewController.delegate = self
    }

    #if targetEnvironment(macCatalyst)
    @objc
    func addWorkspace(_ sender: UIBarButtonItem) {
        guard let splitViewController = window?.rootViewController as? UISplitViewController else { return }
        guard let navigationController = splitViewController.viewControllers.first as? UINavigationController else { return }
        guard let viewController = navigationController.topViewController as? MasterViewController else { return }
        viewController.addWorkspace(sender)
    }
    #endif
}

#if targetEnvironment(macCatalyst)
extension SceneDelegate: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == signInToolbarIdentifier {
            let barButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkspace(_:)))
            let button = NSToolbarItem(itemIdentifier: signInToolbarIdentifier, barButtonItem: barButtonItem)
            return button
        }
        if itemIdentifier == searchToolbarIdentifier {
            let toolbarItem = NSToolbarItem(itemIdentifier: searchToolbarIdentifier)
            let `class` = NSClassFromString("NSSearchField") as! NSObject.Type
            let searchField = `class`.init()

//            searchField.delegate = toolbarItem;
            toolbarItem.setValue(searchField, forKey: "view")
//            toolbarItem.view = searchField as! NSView
//            toolbarItem.maxSize = CGSize(width: 240, height: 44)
//            toolbarItem.textDidChangeHandler = textDidChangeHandler
            toolbarItem.paletteLabel = "Search"
            return toolbarItem;

//            let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
//            let barButtonItem = UIBarButtonItem(customView: searchBar)
//            let button = NSToolbarItem(itemIdentifier: searchToolbarIdentifier, barButtonItem: barButtonItem)
//            return button
        }
        return nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [signInToolbarIdentifier, NSToolbarItem.Identifier.flexibleSpace, searchToolbarIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
}
#endif
