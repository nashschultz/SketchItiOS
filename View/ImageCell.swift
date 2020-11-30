//
//  ImageCell.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class ImageCell: UITableViewCell {
    
    @IBOutlet weak var drawnImage: UIImageView!
    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var wordLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configCell(path: String, userID: String, gameID: String, text: String) {
        roundedView.layer.cornerRadius = 20.0
        wordLabel.text = text
        self.selectionStyle = .none
        let storageReference = Storage.storage().reference()
        let reference = storageReference.child("games").child(gameID).child(path).child("\(userID).jpg")
        let imageView: UIImageView = self.drawnImage
        let placeholderImage = UIImage(named: "tempwhite.png")
        imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
    }

}
