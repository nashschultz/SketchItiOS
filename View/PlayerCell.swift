//
//  PlayerCell.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class PlayerCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var removeButton: UIButton!
    
    var ref: DatabaseReference!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        ref = Database.database().reference()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(name: String, score: Int) {
        self.name.text = name
        self.selectionStyle = .none
        self.roundedView.layer.cornerRadius = 20.0
        
        if removeButton != nil {
            if #available(iOS 13.0, *) {
                //stay
            } else {
                // Fallback on earlier versions
                removeButton.setImage(UIImage(named: "xmark.png"), for: .normal)
            }
        }
    }

}
