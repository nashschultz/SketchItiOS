//
//  SpecificDrawingViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/7/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class SpecificDrawingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var drawingTable: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    var wordList: [String] = []
    var userID: String!
    var gameID: String!
    var roundCount: Int!
    var ref: DatabaseReference!
    var bannerView: GADBannerView!
    var name: String!
    var photoIDs: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        drawingTable.delegate = self
        drawingTable.dataSource = self
        drawingTable.separatorStyle = UITableViewCell.SeparatorStyle.none

        backButton.layer.cornerRadius = 20.0

        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.adUnitID = "ca-app-pub-5912556187565517/8446111558"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        addBannerViewToView(bannerView)
        // Do any additional setup after loading the view.
        loadData()
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
      bannerView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(bannerView)
      view.addConstraints(
        [NSLayoutConstraint(item: bannerView,
                            attribute: .bottom,
                            relatedBy: .equal,
                            toItem: bottomLayoutGuide,
                            attribute: .top,
                            multiplier: 1,
                            constant: 0),
         NSLayoutConstraint(item: bannerView,
                            attribute: .centerX,
                            relatedBy: .equal,
                            toItem: view,
                            attribute: .centerX,
                            multiplier: 1,
                            constant: 0)
        ])
     }
    
        func loadData() {
        wordList.removeAll()
        for n in stride(from: 0, through: roundCount, by: 2){
            let path = "round" + String(n)
            self.ref.child("games").child(self.gameID!).child(path).child(self.userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                let word = snapshot.value as? String ?? "No Word Found"
                self.wordList.append(word)
                if n != self.roundCount {
                    self.photoIDs.append(n + 1)
                }
                // GOT THE WORD
                if n == self.roundCount || n + 1 == self.roundCount {
                    self.drawingTable.reloadData()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        self.ref.child("games").child(gameID).child("players").child(userID).removeValue()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.wordList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell") as? WordCell else {
                return UITableViewCell()
            }
            if wordList.count != 0 {
                cell.configCell(text: self.name + " started at: " + wordList[0])
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell") as? ImageCell else {
                return UITableViewCell()
            }
            if indexPath.row == (self.wordList.count - 1) {
                cell.configCell(path: "round" + String(photoIDs[indexPath.row - 1]), userID: self.userID, gameID: self.gameID, text: self.name + " ended at: " + wordList[indexPath.row])
            } else {
                cell.configCell(path: "round" + String(photoIDs[indexPath.row - 1]), userID: self.userID, gameID: self.gameID, text: wordList[indexPath.row])
            }
            return cell
        }
    } // 1 3 5 7 ---> 0 1 2 3      2 4 6 8 ---> 0 1 2 3
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return CGFloat(75)
        } else {
            return CGFloat(546)
        }
    }
    
    @IBAction func goBack() {
        dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
