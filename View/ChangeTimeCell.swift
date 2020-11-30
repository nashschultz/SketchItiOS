//
//  ChangeTimeCell.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/8/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit

class ChangeTimeCell: UITableViewCell {
    
    @IBOutlet weak var thirtySec: UIButton!
    @IBOutlet weak var fortyFiveSec: UIButton!
    @IBOutlet weak var sixtySec: UIButton!
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
        thirtySec.setTitleColor(.black, for: .normal)
        fortyFiveSec.setTitleColor(.black, for: .normal)
        sixtySec.setTitleColor(.black, for: .normal)
        _sender.setTitleColor(.systemRed, for: .normal)
    }

}
