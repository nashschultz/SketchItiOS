//
//  OtherDrawingsViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/7/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class OtherDrawingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playerTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    var playerList: [String] = []
    var idList: [String] = []
    var selectedPlayer: String!
    var selectedName: String!
    var gameID: String!
    var roundCount: Int!
    var bannerView: GADBannerView!
    var isEven = false
    var userID: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        playerTableView.delegate = self
        playerTableView.dataSource = self
        playerTableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        
        backButton.layer.cornerRadius = 20.0
        // Do any additional setup after loading the view.
        
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.adUnitID = "ca-app-pub-5912556187565517/8446111558"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        addBannerViewToView(bannerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playerTableView.reloadData()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toSpecific"?:
            let destination = segue.destination as! SpecificDrawingViewController
            destination.gameID = self.gameID
            destination.userID = self.selectedPlayer
            destination.name = self.selectedName
            destination.roundCount = self.roundCount
        default:
            return
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playerList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell") as? WordCell else {
            return UITableViewCell()
        }
        cell.configCell(text: "View " + playerList[indexPath.row] + "'s chain")
        return cell
    } // 1 3 5 7 ---> 0 1 2 3      2 4 6 8 ---> 0 1 2 3
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(75)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPlayer = idList[indexPath.row]
        selectedName = playerList[indexPath.row]
        self.performSegue(withIdentifier: "toSpecific", sender: nil)
    }
    
    @IBAction func goBack() {
        dismiss(animated: true, completion: nil)
    }
}
