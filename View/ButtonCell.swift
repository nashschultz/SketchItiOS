//
//  ButtonCell.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/7/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit

class ButtonCell: UITableViewCell {
    
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var roundedView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        roundedView.layer.cornerRadius = 20.0
        self.selectionStyle = .none
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
