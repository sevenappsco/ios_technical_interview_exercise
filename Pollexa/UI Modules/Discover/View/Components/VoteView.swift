//
//  PollView.swift
//  Pollexa
//
//  Created by Adem Özsayın on 7.06.2024.
//

import UIKit
import UIKit

/// A delegate protocol for handling user votes in the `VoteView`.
protocol VoteViewDelegate: AnyObject {
    /// Called when the user votes for an option.
    ///
    /// - Parameters:
    ///   - option: The option that was voted for.
    ///   - indexPath: The index path of the post in the table view.
    func didUserVote(at option: Post.Option, indexPath: IndexPath)
}

/// A view representing a voting option in a post.
class VoteView: UIView {
    
    // MARK: - Properties
    
    /// The container view holding all subviews.
    private var containerView = UIView()
    
    /// The image view displaying the option image.
    private let imageView = UIImageView()
    
    /// The button used to vote for the option.
    private let voteButton = UIButton(type: .system)
    
    /// The label displaying the vote ratio.
    private let ratioLabel = UILabel()
    
    /// The delegate for handling vote actions.
    weak var delegate: VoteViewDelegate?
    
    /// The voting option represented by this view.
    var option: Post.Option?
    
    /// A boolean indicating if the current user has voted for this option.
    var isVotedByCurrentUser: Bool = false {
        didSet {
            updateVoteViewAppearance()
        }
    }
    
    /// A boolean indicating if this option has been voted for.
    var isVoted: Bool = false {
        didSet {
            updateVoteViewAppearance()
        }
    }
    
    /// The index path of the post in the table view.
    var indexPath: IndexPath = IndexPath()
    
    /// The vote ratio for this option.
    var voteRatio: Double = 0.0 {
        didSet {
            updateRatioLabel()
        }
    }
    
    // MARK: - Initializers
    
    /// Initializes the view with the given frame.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    /// Initializes the view from a coder.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    /// Sets up the view by adding and configuring its subviews.
    private func setupView() {
        // Setup containerView
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // Setup imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        // Setup voteButton
        voteButton.setImage(UIImage(named: "vote"), for: .normal)
        voteButton.addTarget(self, action: #selector(voteButtonTapped), for: .touchUpInside)
        voteButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(voteButton)
        NSLayoutConstraint.activate([
            voteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            voteButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        ])
        
        // Setup ratioLabel
        ratioLabel.applyCalloutStyle()
        ratioLabel.textColor = .white
        ratioLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ratioLabel)
        NSLayoutConstraint.activate([
            ratioLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            ratioLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        updateRatioLabel()
    }
    
    // MARK: - Actions
    
    /// Called when the vote button is tapped.
    @objc private func voteButtonTapped() {
        guard let option = option else { return }
        delegate?.didUserVote(at: option, indexPath: self.indexPath)
    }
    
    // MARK: - Update Methods
    
    /// Updates the ratio label based on the current vote ratio.
    private func updateRatioLabel() {
        ratioLabel.isHidden = !isVoted
        ratioLabel.text = String(format: "%.1f%%", voteRatio)
        voteButton.isHidden = isVoted
    }
    
    /// Updates the appearance of the vote view based on the voting state.
    private func updateVoteViewAppearance() {
        if isVotedByCurrentUser {
            layer.borderWidth = 4.0
            layer.borderColor = UIColor.appColor.cgColor
        } else {
            layer.borderWidth = 0.0
            layer.borderColor = UIColor.clear.cgColor
        }
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 1.0
        layer.masksToBounds = false
    }
    
    // MARK: - Configuration
    
    /// Configures the view with the given parameters.
    ///
    /// - Parameters:
    ///   - option: The voting option.
    ///   - isVoted: A boolean indicating if the option is voted.
    ///   - voteRatio: The vote ratio for the option.
    ///   - isVotedByCurrentUser: A boolean indicating if the current user has voted for the option.
    ///   - indexPath: The index path of the post in the table view.
    final func configure(with option: Post.Option, isVoted: Bool, voteRatio: Double, isVotedByCurrentUser: Bool, indexPath: IndexPath) {
        self.imageView.image = option.image
        self.option = option
        self.isVoted = isVoted
        self.voteRatio = voteRatio
        self.isVotedByCurrentUser = isVotedByCurrentUser
        self.indexPath = indexPath
    }
}
