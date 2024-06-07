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

final class PostViewModel: ObservableObject {
    
    typealias CellViewModel = PostTableViewCell.ViewModel

    @Published private(set) var postsViewModels: [CellViewModel] = []

    
    private(set) var posts: [Post] = []
    
    @Published private(set) var state: PostListState = .loading
    
    init()  { 
        Task {
            await fetchPosts()
        }
    }
    
    @MainActor
    func fetchPosts() async {
        do {

            posts = try await loadPages()
            /// simulate loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.buildCouponViewModels()
            }

        } catch {
            print("⛔️ Error loading pages: \(error)")
            state = .empty
        }
    }
    
    func buildCouponViewModels() {
        postsViewModels = posts.map { post in
            CellViewModel(
                title: post.content,
                username: post.user?.username ?? "-",
                avatar: post.user?.image ?? nil,
                date: post.createdAt,
                lastVotedDate: post.lastVoteAt ?? nil,
                totalVoteCount: post.options.reduce(0) { $0 + $1.voted }
            )
        }
        
        if !postsViewModels.isEmpty {
            state = .posts
        } else {
            state = .empty
        }
    }
}

private extension PostViewModel {
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
//
private extension PostViewModel {
    func transitionToSyncingState(pageNumber: Int, hasData: Bool) {
        if pageNumber == 1 {
            state = hasData ? .refreshing : .loading
        } else {
            state = .loadingNextPage
        }
    }
    
    func transitionToResultsUpdatedState(hasData: Bool) {
        if hasData {
            state = .posts
        } else {
            state = .empty
        }
    }
}


extension PostViewModel {
   
    enum State: Equatable {
        case pagesLoading
        case pagesLoadingError
        case pagesContent
    }
    
    private enum Localization {
        static let homePage = NSLocalizedString(
            "Discover",
            value: "Discover",
            comment: "Page title of Discover page"
        )
    }
}
