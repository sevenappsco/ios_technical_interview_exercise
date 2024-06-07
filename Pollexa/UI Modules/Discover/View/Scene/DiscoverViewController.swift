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
    
    /// The view model that provides data for the view controller.
    private let viewModel: PostViewModel
    
    /// A set of AnyCancellable instances to store Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    /// The table view displaying the posts.
    @IBOutlet private weak var tableView: UITableView!
    
    /// An optional view controller displayed when the list is empty.
    private var emptyStateViewController: UIViewController?
    
    /// A lazy property that creates and configures a GhostTableViewController for displaying placeholder cells.
    lazy var ghostTableViewController = GhostTableViewController(
        options: GhostTableViewOptions(
            cellClass: PostTableViewCell.self,
            rowsPerSection: Constants.placeholderRowsPerSection,
            estimatedRowHeight: Constants.estimatedRowHeight,
            backgroundColor: .basicBackground
        )
    )
    
    /// Pull-to-refresh control for refreshing the post list.
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        return refreshControl
    }()
    
    /// A set of AnyCancellable instances to store Combine subscriptions.
    private var subscriptions: Set<AnyCancellable> = []
    
    /// A diffable data source for managing the table view's data.
    private lazy var dataSource: UITableViewDiffableDataSource<Section, PostViewModel.CellViewModel> = makeDataSource()
    
    /// Initializes the view controller with a view model.
    ///
    /// - Parameter viewModel: The view model that provides data for the view controller.
    init(viewModel: PostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Initializes the view controller from a coder.
    ///
    /// - Parameter coder: The coder to initialize from.
    required init?(coder: NSCoder) {
        self.viewModel = PostViewModel()
        super.init(coder: coder)
    }

    // MARK: - Life Cycle
    
    /// Called after the view controller's view has been loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureTableView()
        configureViewModel()
    }
    
    /// Triggers a refresh for the post list.
    ///
    /// This method is called when the user performs a pull-to-refresh action.
    @objc func refreshList() {
        // End refreshing state
        refreshControl.endRefreshing()
    }

}

// MARK: - View Configuration
//
private extension DiscoverViewController {
    
    // MARK: - Private Methods
    
    /// Sets up the navigation bar.
    final func setupNavigationBar() {
        
        // Set up the view controller to prefer large titles
        navigationItem.title = viewModel.pageTitle
        navigationItem.largeTitleDisplayMode = .always

        let avatarImageView = UIImageView(image: UIImage(named: "avatar_6"))
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        
        // Create the left bar button item with the avatar image view
        let leftBarButtonItem = UIBarButtonItem(customView: avatarImageView)
        
        // Create the right bar button item with a plus icon
        let plusIcon = UIImage(systemName: "plus") // Use a system icon or your own icon
        let rightBarButtonItem = UIBarButtonItem(image: plusIcon, style: .plain, target: self, action: #selector(plusButtonTapped))
        
        // Set the left and right bar button items to the navigation bar
        navigationItem.leftBarButtonItem = leftBarButtonItem
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    @objc func plusButtonTapped() {}
    
    final func configureTableView() {
        registerTableViewCells()
        tableView.dataSource = dataSource
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.addSubview(refreshControl)
        tableView.delegate = self
        tableView.backgroundColor = .discoverBackground
        tableView.separatorStyle = .none
    }
    
    final func registerTableViewCells() {
        PostTableViewCell.register(for: tableView)
    }
    
    // Creates and returns a diffable data source for the table view.
    ///
    /// - Returns: A configured diffable data source.
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
}
 
// MARK: - VoteViewDelegate

extension DiscoverViewController: VoteViewDelegate {
    final func didUserVote(at option: Post.Option, indexPath: IndexPath ) {
        viewModel.vote(at: option, indexPath: indexPath)
    }
}

private extension DiscoverViewController {
    /// Configures the view model bindings.

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
                guard let self  else { return }
                self.applySnapshot(posts: posts)
            }
            .store(in: &subscriptions)
    }
    
    /// Updates the table view with the given posts.
    ///
    /// - Parameter posts: The new posts to display.
    final func applySnapshot(posts: [PostViewModel.CellViewModel]) {
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
///
///Since data is local and we know will not be empty
///no need to integrate empty screen
private extension DiscoverViewController {
    /// Displays the overlay when there are no results.
    ///
    final func displayNoResultsOverlay() {}
    
    /// Shows the EmptyStateViewController as a child view controller.
    ///
    final func displayEmptyStateViewController(_ emptyStateViewController: UIViewController) {}
    
    /// Removes EmptyStateViewController child view controller if applicable.
    ///
    final func removeNoResultsOverlay() {}
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
