import UIKit
import AuthenticationServices
import Combine

class MasterViewController: UITableViewController {
    private var cancellables = Set<AnyCancellable>()
    private var workspaceSession = WorkspaceSession()

    private var dataSource: UITableViewDiffableDataSource<String, Channel>!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.circle"), style: .plain, target: self, action: #selector(addWorkspace(_:)))
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: false)
        #endif

        tableView.register(UINib(nibName: String(describing: ChannelCell.self), bundle: nil), forCellReuseIdentifier: String(describing: ChannelCell.self))
        configureDataSource()
        tableView.dataSource = self

        let workspaceSession = self.workspaceSession
        workspaceSession.$accessToken
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in

            }, receiveValue: { _ in
                workspaceSession.bootstrap()
            })
            .store(in: &cancellables)

        workspaceSession.$workspace
            .compactMap { $0?.channels }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                var snapshot = NSDiffableDataSourceSnapshot<String, Channel>()
                snapshot.appendSections(["Channels"])
                snapshot.appendItems($0)
                self?.dataSource.apply(snapshot, animatingDifferences: false)
        }
        .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        #if targetEnvironment(macCatalyst)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let bridge = appDelegate.appKitSupport {
                bridge.setValue("main", forKey: "windowIdentifier")
            }
        }
        #endif
    }

    private func configureDataSource() {
        #if targetEnvironment(macCatalyst)
        let selector = #selector(handleTapCell(_:))
        #endif

        dataSource = UITableViewDiffableDataSource<String, Channel>(tableView: tableView) { (tableView, indexPath, identifier) in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ChannelCell.self), for: indexPath) as! ChannelCell
            cell.channel = identifier

            #if targetEnvironment(macCatalyst)
            cell.tapGestureRecognizer.addTarget(self, action: selector)
            #endif

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let workspace = workspaceSession.workspace else { return }
        let viewController = DetailViewController(workspaceSession: workspaceSession, channel: workspace.channels[indexPath.row])
        splitViewController?.showDetailViewController(viewController, sender: self)
    }

    #if targetEnvironment(macCatalyst)
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        
        let label = UILabel()
        label.text = dataSource.snapshot().sectionIdentifiers[section]
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .systemGray

        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
        ])

        return view
    }
    #else
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource.snapshot().sectionIdentifiers[section]
    }
    #endif

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections(in: tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dataSource.tableView(tableView, cellForRowAt: indexPath)
    }

    @objc
    private func handleTapCell(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: location) {
            if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
                if indexPath != indexPathForSelectedRow {
                    selectRow(indexPath: indexPath)
                }
            } else {
                selectRow(indexPath: indexPath)
            }
        }
    }

    func selectRow(indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }

    @objc
    func addWorkspace(_ sender: UIBarButtonItem) {
        let workspaceSession = self.workspaceSession

        Future<String, Never> { [weak self] promise in
            let authenticationSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackURLScheme) { (callbackURL, error) in
                if let _ = error {
                    return
                }
                guard let callbackURL = callbackURL else {
                    return
                }
                if let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
                    promise(.success(code))
                }
            }

            authenticationSession.presentationContextProvider = self
            authenticationSession.prefersEphemeralWebBrowserSession = true
            authenticationSession.start()
        }
        .setFailureType(to: APIError.self)
        .flatMap { code in
            workspaceSession.authorize(clientID: clientID, clientSecret: clientSecret, code: code)
        }
        .sink(receiveCompletion: { _ in

        }, receiveValue: {
            workspaceSession.accessToken = $0.accessToken
            workspaceSession.workspace = Workspace(name: $0.teamName)
        })
        .store(in: &cancellables)
    }
}

extension MasterViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
