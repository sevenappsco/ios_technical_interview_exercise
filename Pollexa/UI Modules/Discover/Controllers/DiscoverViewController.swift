//
//  DiscoverViewController.swift
//  Pollexa
//
//  Created by Emirhan Erdogan on 13/05/2024.
//

import UIKit

class DiscoverViewController: UIViewController {

    // MARK: - Properties
    private let postProvider = PostProvider.shared

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postProvider.fetchAll { result in
            switch result {
            case .success(let posts):
                print(posts)
                
            case .failure(let error):
                debugPrint(error.localizedDescription)
            }
        }
    }
}
