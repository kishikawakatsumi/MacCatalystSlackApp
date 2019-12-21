import UIKit

final class ImagePanelWindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        let viewController = ImagePanelViewController()
        if let url = connectionOptions.userActivities.first?.userInfo?["image"] as? String, let imageURL = URL(string: url) {
            viewController.imageURL = imageURL
        }

        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
}

final class ImagePanelViewController: UIViewController {
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let imageView = UIImageView()
    var imageURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor( red: 83/255, green: 87/255, blue: 96/255, alpha: 1)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        if let imageURL = imageURL {
            ImagePipeline.shared.load(imageURL, into: imageView)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let bridge = appDelegate.appKitSupport {
                bridge.setValue("panel", forKey: "windowIdentifier")
            }
        }
    }
}
