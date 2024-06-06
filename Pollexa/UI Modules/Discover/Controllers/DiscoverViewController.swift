//
//  DiscoverViewController.swift
//  Pollexa
//
//  Created by Emirhan Erdogan on 13/05/2024.
//

import UIKit
import Combine

class DiscoverViewController: UIViewController {

    // MARK: - Properties
    private let postProvider = PostProvider.shared
    private let viewModel: PostViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: PostViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = PostViewModel() // Or provide a default value, if possible
        super.init(coder: coder)
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        observeViewModel()
    }
}

private extension DiscoverViewController {
    final func observeViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        viewModel.$posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                self?.handlePostsUpdate(posts)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: PostViewModel.State) {
        switch state {
            case .pagesLoading:
                print("loading")
            case .pagesLoadingError:
                print("error")
            case .pagesContent:
                print("content loaded")
        }
    }
    
    private func handlePostsUpdate(_ posts: [Post]) {
        print("Number of posts: \(posts.count)")
    }
}
