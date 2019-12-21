import UIKit
import Combine

class DetailViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    private var workspaceSession: WorkspaceSession
    private var channel: Channel

    private let tableView = UITableView()

    init(workspaceSession: WorkspaceSession, channel: Channel) {
        self.workspaceSession = workspaceSession
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var dataSource: UITableViewDiffableDataSource<String, Message>!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.register(UINib(nibName: String(describing: TextMessageCell.self), bundle: nil), forCellReuseIdentifier: String(describing: TextMessageCell.self))
        configureDataSource()

        workspaceSession.$workspace
            .compactMap { $0?.messageStore }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                if let messages = $0[self.channel.id] {
                    var snapshot = NSDiffableDataSourceSnapshot<String, Message>()
                    snapshot.appendSections([""])
                    snapshot.appendItems(messages)
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                }
        }
        .store(in: &cancellables)
    }

    private func configureDataSource() {
        let workspaceSession = self.workspaceSession

        dataSource = UITableViewDiffableDataSource<String, Message>(tableView: tableView) { (tableView, indexPath, identifier) in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TextMessageCell.self), for: indexPath) as! TextMessageCell
            switch identifier {
            case .text(let message):
                cell.message = message

                cell.cancellable = workspaceSession.userInfo(for: message.user)
                    .receive(on: RunLoop.main)
                    .sink(receiveCompletion: {_ in
                        
                    }) {
                        cell.updateUserProfile($0.user.profile)
                    }

                return cell
            }
        }
    }
}
