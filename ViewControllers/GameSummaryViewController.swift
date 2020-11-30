//
//  GameSummaryViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class GameSummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GADInterstitialDelegate {
    
    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var backToLobbyButton: UIButton!
    @IBOutlet weak var rematchButton: UIButton!
    
    var wordList: [String] = []
    var userID: String!
    var gameID: String!
    var name: String!
    var nameList: [String] = []
    var idList: [String] = []
    var isHost = false
    var roundCount: Int!
    var ref: DatabaseReference!
    var interstitial: GADInterstitial!
    var photoIDs: [Int] = []
    var isEven = false
    var toLobby = false

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()
        
        self.summaryTableView.delegate = self
        self.summaryTableView.dataSource = self
        self.summaryTableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        backToLobbyButton.layer.cornerRadius = 20.0
        rematchButton.layer.cornerRadius = 20.0
        
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-5912556187565517/7010768625")
        let request = GADRequest()
        interstitial.load(request)
        interstitial.delegate = self
        
        
        loadData()
        observeForRematch()
        
        if isEven == true {
            let index = idList.firstIndex(of: self.userID)
            if index != nil {
                idList.remove(at: index!)
                nameList.remove(at: index!)
            }
        }
        // Do any additional setup after loading the view.
    }
    
    func loadData() {
        wordList.removeAll()
        for n in stride(from: 0, through: roundCount, by: 2){
            let path = "round" + String(n)
            self.ref.child("games").child(self.gameID!).child(path).child(self.userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                let word = snapshot.value as? String ?? "Draw Anything"
                self.wordList.append(word)
                if n != self.roundCount {
                    self.photoIDs.append(n + 1)
                }
                // GOT THE WORD
                if n == self.roundCount || n + 1 == self.roundCount {
                    self.summaryTableView.reloadData()
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        self.ref.child("games").child(gameID).child("players").child(userID).removeValue()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.wordList.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell") as? WordCell else {
                return UITableViewCell()
            }
            if wordList.count != 0 {
                cell.configCell(text: "You started at: " + wordList[0])
            }
            return cell
        } else if indexPath.row == (self.wordList.count) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as? ButtonCell else {
                return UITableViewCell()
            }
            cell.goButton.addTarget(self, action: #selector(goToSpecific), for: .touchUpInside)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell") as? ImageCell else {
                return UITableViewCell()
            }
            if indexPath.row == (self.wordList.count - 1) {
                cell.configCell(path: "round" + String(self.photoIDs[indexPath.row - 1]), userID: self.userID, gameID: self.gameID, text: "You ended at: " + wordList[indexPath.row])
            } else {
                cell.configCell(path: "round" + String(self.photoIDs[indexPath.row - 1]), userID: self.userID, gameID: self.gameID, text: wordList[indexPath.row])
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 || indexPath.row == wordList.count {
            return CGFloat(75)
        } else {
            return CGFloat(546)
        }
    }
    
    @objc func goToSpecific() {
        self.performSegue(withIdentifier: "toSpecific", sender: nil)
    }
    
    @IBAction func goBackToLobby() {
        self.ref.removeAllObservers()
        toLobby = true
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            self.ref.child("games").child(self.gameID).child("lock").removeAllObservers()
            self.performSegue(withIdentifier: "toLobby", sender: nil)
        }
    }
    
    @IBAction func rematchClicked() {
        self.ref.removeAllObservers()
        if isHost == true {
            if interstitial.isReady {
                interstitial.present(fromRootViewController: self)
            } else {
                self.ref.child("games").child(self.gameID).child("lock").removeAllObservers()
                self.performSegue(withIdentifier: "toCreate", sender: nil)
            }
        } else {
            if interstitial.isReady {
                interstitial.present(fromRootViewController: self)
            } else {
                self.ref.child("games").child(self.gameID).child("lock").removeAllObservers()
                self.performSegue(withIdentifier: "toJoin", sender: nil)
            }
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        if toLobby == true {
            self.ref.child("games").child(self.gameID).child("lock").removeAllObservers()
            performSegue(withIdentifier: "toLobby", sender: nil)
        } else {
            if isHost == true {
                self.ref.child("games").child(self.gameID).child("lock").removeAllObservers()
                self.performSegue(withIdentifier: "toCreate", sender: nil)
            } else {
                self.ref.child("games").child(self.gameID).child("lock").removeAllObservers()
                self.performSegue(withIdentifier: "toJoin", sender: nil)
            }
        }
    }
    
    func observeForRematch() {
        if isHost == true {
            self.rematchButton.setTitle("Rematch", for: .normal)
            self.rematchButton.alpha = 1.0
        } else {
            self.ref.child("games").child(self.gameID).child("lock").observe(.value) { snapshot in
                let lock = snapshot.value as? Int
                if lock == 0 {
                    self.rematchButton.setTitle("Rematch", for: .normal)
                    self.rematchButton.alpha = 1.0
                }
                if self.rematchButton.alpha == 1.0 && lock == 1 {
                    self.toLobby = true
                    if self.interstitial.isReady {
                        self.interstitial.present(fromRootViewController: self)
                    } else {
                        self.ref.child("games").child(self.gameID).child("lock").removeAllObservers()
                        self.performSegue(withIdentifier: "toLobby", sender: nil)
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toCreate"?:
            let destination = segue.destination as! CreateGameViewController
            destination.currentName = self.name
            destination.userID = self.userID
            destination.isRematch = true
            destination.finalGameID = self.gameID
        case "toJoin"?:
            let destination = segue.destination as! JoinGameViewController
            destination.currentName = self.name
            destination.userID = self.userID
            destination.isRematch = true
            destination.finalGameID = self.gameID
        case "toSpecific"?:
            let destination = segue.destination as! OtherDrawingsViewController
            destination.idList = self.idList
            destination.gameID = self.gameID
            destination.playerList = self.nameList
            destination.roundCount = self.roundCount
            destination.isEven = self.isEven
            destination.userID = self.userID
        default:
            return
        }
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
