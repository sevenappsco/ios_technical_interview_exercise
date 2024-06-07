//
//  PostViewModel.swift
//  Pollexa
//
//  Created by Adem Özsayın on 6.06.2024.
//

import Foundation
import Combine

enum PostListState {
    case initialized
    case loading // View should show ghost cells
    case empty // View should display the empty state
    case posts
    case refreshing // View should display the refresh control
    case loadingNextPage
}

/// A view model for managing and displaying a list of posts.
final class PostViewModel: ObservableObject {
    
    /// The type used for cell view models.
    typealias CellViewModel = PostTableViewCell.ViewModel
    
    /// An array of cell view models for displaying posts in the UI.
    @Published private(set) var postsViewModels: [CellViewModel] = []
    
    /// The currently logged-in user.
    @Published private(set) var currentUser: User?
    
    /// An array of `Post` objects.
    private(set) var posts: [Post] = [] 
    /// The current state of the post list.
    @Published private(set) var state: PostListState = .loading
    
    /// The title of the page.
    @Published private(set) var pageTitle: String = Localization.pageTitle
    
    /// Initializes the view model and begins fetching posts.
    init()  {
        Task {
            await fetchPosts()
        }
    }
    
    // MARK: - Methods
    
    /// Fetches posts asynchronously and updates the state and current user.
    @MainActor
    func fetchPosts() async {
        do {
            posts = try await loadPages()
            currentUser = posts.first?.user ?? nil
            buildCouponViewModels()
        } catch {
            print("⛔️ Error loading pages: \(error)")
            state = .empty
        }
    }
    
    /// Builds view models for the posts and updates the state.
    func buildCouponViewModels() {
        postsViewModels = posts.map { post in
            CellViewModel(
                id: post.id,
                title: post.content,
                username: post.user?.username ?? "-",
                avatar: post.user?.image ?? nil,
                date: post.createdAt,
                lastVotedDate: post.lastVoteAt ?? nil,
                totalVoteCount: post.options.reduce(0) { $0 + $1.voted },
                options: post.options,
                isVoted: post.votedBys.contains { votedBy in
                    votedBy.postId == post.id && post.options.contains { $0.id == votedBy.selectedOption.id }
                },
                currentUser: currentUser,
                votedUsers: post.votedBys
            )
        }
        /// Simulate Data
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.state = self.postsViewModels.isEmpty ? .empty : .posts
        }
       
    }
    
    /// Votes for a specific option in a post and updates the view models.
    ///
    /// - Parameters:
    ///   - option: The option to vote for.
    ///   - indexPath: The index path of the post in the table view.
    func vote(at option: Post.Option, indexPath: IndexPath) {
        let postIndex = indexPath.row
        let post = posts[postIndex]
        guard let optionIndex = post.options.firstIndex(where: { $0.id == option.id }) else {
            return
        }
        
        // Update the voted count
        posts[postIndex].options[optionIndex].voted += 1
        
        // Append the current user to the votedBys array
        var updatedPost = posts[postIndex]
        let votedBy = VotedBy(
            user: currentUser!,
            postId: posts[postIndex].id,
            selectedOption: option
        )
        updatedPost.votedBys.append(votedBy)
        
        // Replace the old post with the updated one
        posts[postIndex] = updatedPost
        
        buildCouponViewModels()
    }
}

// MARK: - Private Methods

private extension PostViewModel {
    
    /// Loads pages of posts asynchronously.
    ///
    /// - Returns: An array of `Post` objects.
    /// - Throws: An error if the pages could not be loaded.
    @MainActor
    func loadPages() async throws -> [Post] {
        try await withCheckedThrowingContinuation { continuation in
            PostProvider.shared.fetchAll { result in
                switch result {
                    case .success(let pages):
                        continuation.resume(returning: pages)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Pagination

private extension PostViewModel {
    
    /// Transitions the state to syncing based on the page number and whether there is data.
    ///
    /// - Parameters:
    ///   - pageNumber: The current page number.
    ///   - hasData: A boolean indicating whether there is data.
    func transitionToSyncingState(pageNumber: Int, hasData: Bool) {
        if pageNumber == 1 {
            state = hasData ? .refreshing : .loading
        } else {
            state = .loadingNextPage
        }
    }
    
    /// Transitions the state to updated results based on whether there is data.
    ///
    /// - Parameter hasData: A boolean indicating whether there is data.
    func transitionToResultsUpdatedState(hasData: Bool) {
        state = hasData ? .posts : .empty
    }
}

// MARK: - State and Localization

extension PostViewModel {
    
    /// The different states the post list can be in.
    enum State: Equatable {
        case pagesLoading
        case pagesLoadingError
        case pagesContent
    }
    
    /// Localized strings used in the view model.
    private enum Localization {
        static let pageTitle = NSLocalizedString(
            "Discover",
            value: "Discover",
            comment: "Page title of Discover page"
        )
    }
}
