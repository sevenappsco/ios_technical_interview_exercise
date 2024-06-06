//
//  PostViewModel.swift
//  Pollexa
//
//  Created by Adem Özsayın on 6.06.2024.
//

import Foundation
import Combine

final class PostViewModel: ObservableObject {
    @Published private(set) var posts: [Post] = []
    @Published private(set) var state: State = .pagesLoading
    
    init()  { 
        Task {
            await fetchPosts()
        }
    }
    
    @MainActor
    func fetchPosts() async {
        do {

            posts = try await loadPages()
            
            state = .pagesContent
        } catch {
            print("⛔️ Error loading pages: \(error)")
            state = .pagesLoadingError
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
