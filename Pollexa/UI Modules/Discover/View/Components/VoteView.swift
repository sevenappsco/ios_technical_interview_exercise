//
//  PollView.swift
//  Pollexa
//
//  Created by Adem Özsayın on 7.06.2024.
//

import UIKit

protocol VoteViewDelegate: AnyObject {
    func didUserVote(at option: Post.Option)
}

class VoteView: UIView {

    private var containerView = UIView()
    private let imageView = UIImageView()
    private let voteButton = UIButton(type: .system)
    private let ratioLabel = UILabel()
    
    weak var delegate: VoteViewDelegate?
    
    var option: Post.Option?
    
    
    var isVoted: Bool = false {
        didSet {
            updateRatioLabel()
        }
    }
    
    var voteRatio: Double = 0.0 {
        didSet {
            updateRatioLabel()
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    
    private func setupView() {
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])        
        
        // Setup imageView
//        imageView.contentMode = .scaleToFill
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
    
    @objc private func voteButtonTapped() {
        guard let option = option else { return }
        delegate?.didUserVote(at: option)
    }
    
    private func updateRatioLabel() {
        ratioLabel.isHidden = !isVoted
        
        ratioLabel.text = String(format: "%.1f%%", voteRatio )
        voteButton.isHidden = isVoted
    }
    
    func configure(with option: Post.Option, isVoted: Bool, voteRatio: Double) {
        self.imageView.image = option.image
        self.option = option
        self.isVoted = isVoted
        self.voteRatio = voteRatio
    }
}
