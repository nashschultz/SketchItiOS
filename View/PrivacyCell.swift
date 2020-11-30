//
//  PrivacyCell.swift
//  SketchIt
//
//  Created by Nash Schultz on 11/29/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit

class PrivacyCell: UITableViewCell {
    
    @IBOutlet weak var publicButton: UIButton!
    @IBOutlet weak var privateButton: UIButton!
    @IBOutlet weak var roundedView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        roundedView.layer.cornerRadius = 20.0
        roundedView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func buttonClicked(_sender: UIButton) {
        publicButton.setTitleColor(.black, for: .normal)
        privateButton.setTitleColor(.black, for: .normal)
        _sender.setTitleColor(.systemRed, for: .normal)
    }

}
