//
//  WordCell.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit

class WordCell: UITableViewCell {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var roundedView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(text: String) {
        roundedView.layer.cornerRadius = 20.0
        wordLabel.text = text
        self.selectionStyle = .none
    }

}
