//
//  Post.swift
//  Pollexa
//
//  Created by Emirhan Erdogan on 13/05/2024.
//

import UIKit

struct Post: Decodable {
    
    // MARK: - Properties
    let id: String
    let createdAt: Date
    let content: String
    var options: [Option]
    let user: User?
    let lastVoteAt: Date?
    var votedBys: [VotedBy]
}

struct VotedBy: Decodable, Hashable {
    var user: User
    var postId: String?
    var selectedOption: Post.Option
}
