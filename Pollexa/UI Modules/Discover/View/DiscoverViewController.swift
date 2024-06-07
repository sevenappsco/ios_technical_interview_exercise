//
//  DiscoverViewController.swift
//  Pollexa
//
//  Created by Emirhan Erdogan on 13/05/2024.
//

import UIKit
import Combine

class DiscoverViewController: UIViewController, GhostableViewController {

    // MARK: - Properties
    private let viewModel: PostViewModel
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private weak var tableView: UITableView!
    /// Set when an empty state view controller is displayed.
    ///
    private var emptyStateViewController: UIViewController?
    
    lazy var ghostTableViewController = GhostTableViewController(
        options: GhostTableViewOptions(
            cellClass: PostTableViewCell.self,
            rowsPerSection: Constants.placeholderRowsPerSection,
            estimatedRowHeight: Constants.estimatedRowHeight,
            backgroundColor: .basicBackground))
    
    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        return refreshControl
    }()
    
    private var subscriptions: Set<AnyCancellable> = []
    
    private lazy var dataSource: UITableViewDiffableDataSource<Section, PostViewModel.CellViewModel> = makeDataSource()

    init(viewModel: PostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = PostViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureViewModel()
    }
    
    /// Triggers a refresh for the coupon list
    ///
    @objc func refreshList() {
        // 
        refreshControl.endRefreshing()
    }
}

// MARK: - View Configuration
//
private extension DiscoverViewController {
    func configureTableView() {
        registerTableViewCells()
        
        tableView.dataSource = dataSource
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.addSubview(refreshControl)
        tableView.delegate = self
        tableView.backgroundColor = .discoverBackground
        tableView.separatorStyle = .none
        
    }
    
    func registerTableViewCells() {
        PostTableViewCell.register(for: tableView)
    }
    
    func makeDataSource() -> UITableViewDiffableDataSource<Section, PostViewModel.CellViewModel> {
        let reuseIdentifier = PostTableViewCell.reuseIdentifier
        return UITableViewDiffableDataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, cellViewModel in
                let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
                if let cell = cell as? PostTableViewCell {
                    cell.configureCell(viewModel: cellViewModel, indexPath: indexPath)
                    cell.voteView1.delegate = self
                    cell.voteView2.delegate = self
                }
                return cell
            }
        )
    }
    
//    func handleVote(for voteView: VoteView?) {
//        guard let voteView = voteView, let option = voteView.option else { return }
//        // Delegate the vote action to the view model
//        viewModel.vote(at: option)
//    }
}
    
extension DiscoverViewController: VoteViewDelegate {
    func didUserVote(at option: Post.Option, indexPath: IndexPath ) {
        viewModel.vote(at: option, indexPath: indexPath)
    }
}

private extension DiscoverViewController {
    final func configureViewModel() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                self.resetViews()
                switch state {
                    case .empty:
                        self.displayNoResultsOverlay()
                    case .loading:
                        self.displayPlaceholderCoupons()
                    case .posts:
                        break
                    case .refreshing:
                        self.refreshControl.beginRefreshing()
                    case .loadingNextPage:
                        print("load next page")
                    case .initialized:
                        break
                }
            }
            .store(in: &subscriptions)
        
        viewModel.$postsViewModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                guard let self = self else { return }
                self.applySnapshot(posts: posts)
            }
            .store(in: &subscriptions)
    }
    
    private func applySnapshot(posts: [PostViewModel.CellViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, PostViewModel.CellViewModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(posts, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - TableView Delegate
extension DiscoverViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// MARK: - Placeholder cells
extension DiscoverViewController {
    /// Renders the Placeholder Coupons
    func displayPlaceholderCoupons() {
        displayGhostContent()
    }
    
    /// Removes the Placeholder Coupons
    ///
    func removePlaceholderCoupons() {
        removeGhostContent()
    }
}

// MARK: - Actions
private extension DiscoverViewController {
    /// Removes overlays and loading indicators if present.
    ///
    func resetViews() {
        removeNoResultsOverlay()
        removePlaceholderCoupons()
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }
}

// MARK: - Empty state view controller
//
private extension DiscoverViewController {
    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {}
    
    /// Shows the EmptyStateViewController as a child view controller.
    ///
    func displayEmptyStateViewController(_ emptyStateViewController: UIViewController) {}
    
    /// Removes EmptyStateViewController child view controller if applicable.
    ///
    func removeNoResultsOverlay() {}
}

// MARK: - Nested Types
//
private extension DiscoverViewController {
    enum Constants {
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }
    
    enum Section: Int {
        case main
    }
}
