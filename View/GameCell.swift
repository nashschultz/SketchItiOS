//
//  GameCell.swift
//  SketchIt
//
//  Created by Nash Schultz on 11/29/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit

class GameCell: UITableViewCell {
    
    @IBOutlet weak var gameLabel: UILabel!
    @IBOutlet weak var playerCount: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var roundView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        joinButton.layer.cornerRadius = 20.0
        roundView.layer.cornerRadius = 20.0
        roundView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(game: Game) {
        self.gameLabel.text = game.ownerName + "'s Game"
        self.playerCount.text = String(game.totalPlayers) + "/12"
    }

}
