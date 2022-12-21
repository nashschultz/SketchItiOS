//
//  CreateGameViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class CreateGameViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var gameCodeLabel: UILabel!
    @IBOutlet weak var playerTableView: UITableView!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var ref = Database.database().reference()
    var finalGameID: String?
    var nameList: [String] = []
    var idList: [String] = []
    var currentName: String?
    var userID: String?
    var isRematch = false
    var time = 45
    var privacy = "private"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton.layer.cornerRadius = 20.0
        shareButton.layer.cornerRadius = 20.0
        
        self.playerTableView.delegate = self
        self.playerTableView.dataSource = self
        
        self.playerTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        createGame()
    }
    
    func createGame() {
        if isRematch == false {
            let gameID = String(Int.random(in: 100000 ... 999999))
            ref.child("games").child(gameID).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                // Get user value
                guard let self = self else { return }
                
                let value = snapshot.value as? NSDictionary
                let numPlayers = value?["count"] as? String ?? ""
                if numPlayers == "" {
                    self.finalGameID = gameID
                    self.codeGenerated()
                } else {
                    self.createGame()
                }
                }) { (error) in
                    print(error.localizedDescription)
                }
        } else {
            codeGenerated()
        }
    }
    
    func codeGenerated() {
        gameCodeLabel.text = finalGameID
        guard let finalGameID = finalGameID else { return }
        
        if isRematch == true {
            self.ref.child("games").child(finalGameID).updateChildValues(["count": 1,
                                                                      "round" : 0,
                                                                      "lock" : 0,
                                                                      "timestamp" : Firebase.ServerValue.timestamp(),
                                                                      "players" : [userID : [
                                                                                                  "name": currentName as Any,
                                                                                                  "timestamp": Firebase.ServerValue.timestamp()]]
            ])
        } else {
            ref.child("games").child(finalGameID).setValue(["count": 1,
                                                                      "security" : "private",
                                                                      "round" : 0,
                                                                      "lock" : 0,
                                                                      "timestamp" : Firebase.ServerValue.timestamp(),
                                                                      "players" : [userID : [
                                                                                                  "name": currentName as Any,
                                                                        "timestamp": Firebase.ServerValue.timestamp()]]
            ])
        }
        
        ref.child("games").child(finalGameID).child("players").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            self.nameList.removeAll()
            self.idList.removeAll()
            for rest in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                let postDict = rest.value as? [String : AnyObject] ?? [:]
                if let name = postDict["name"] as? String {
                    self.nameList.append(name)
                    self.idList.append(rest.key)
                }
            }
            
            self.playerTableView.reloadData()
            self.playerLabel.text = "Players: " + String(self.nameList.count) + "/12"
            self.ref.child("games").child(finalGameID).child("count").setValue(self.nameList.count)
            if self.nameList.count > 1 {
                self.startButton.alpha = 1.0
                self.startButton.setTitle("Start Game", for: .normal)
                self.startButton.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc func removePlayer(_sender: AnyObject) {
        guard let finalGameID = finalGameID else { return }
        let buttonPosition = _sender.convert(CGPoint.zero, to: self.playerTableView)
        guard let indexPath: IndexPath = playerTableView.indexPathForRow(at: buttonPosition) else { return }
        ref.child("games").child(finalGameID).child("players").child(idList[indexPath.row - 1]).removeValue()
    }
    
    @IBAction func startTheGame() {
        guard let finalGameID = finalGameID else { return }
        if startButton.alpha == 1.0 {
            ref.child("games").child(finalGameID).updateChildValues(["lock": 1, "time" : self.time])
            ref.child("games").child(finalGameID).child("players").removeAllObservers()
            performSegue(withIdentifier: "toGame", sender: nil)
        }
    }
    
    @IBAction func leaveGame() {
        ref.removeAllObservers()
        if let finalGameID = finalGameID, !isRematch {
            ref.child("games").child(finalGameID).removeValue()
        } else if let finalGameID = finalGameID, isRematch {
            ref.child("games").child(finalGameID).child("players").removeValue()
            ref.child("games").child(finalGameID).child("lock").setValue(1)
        }
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toGame"?:
            guard let destination = segue.destination as? NewWordViewController else { return }
            destination.name = self.currentName
            destination.userID = self.userID
            destination.gameID = self.finalGameID
            destination.nameList = self.nameList
            destination.isHost = true
        default:
            return
        }
    }
    
    @objc func changeTime(_sender: UIButton) {
        if _sender.titleLabel!.text == "45s" {
            time = 45
        } else if _sender.titleLabel!.text == "30s" {
            time = 30
        } else if _sender.titleLabel!.text == "60s" {
            time = 60
        }
    }
    
    @objc func changePrivacy(_sender: UIButton) {
        guard let finalGameID = finalGameID else { return }
        if _sender.titleLabel!.text == "Public" {
            privacy = "public"
            ref.child("games").child(finalGameID).updateChildValues(["security": privacy])
        } else if _sender.titleLabel!.text == "Private" {
            privacy = "private"
            ref.child("games").child(finalGameID).updateChildValues(["security": privacy])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameList.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChangeTimeCell") as? ChangeTimeCell else {
                 return UITableViewCell()
             }
            cell.thirtySec.addTarget(self, action: #selector(changeTime), for: .touchUpInside)
            cell.fortyFiveSec.addTarget(self, action: #selector(changeTime), for: .touchUpInside)
            cell.sixtySec.addTarget(self, action: #selector(changeTime), for: .touchUpInside)
            return cell
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PrivacyCell") as? PrivacyCell else {
                 return UITableViewCell()
             }
            cell.publicButton.addTarget(self, action: #selector(changePrivacy), for: .touchUpInside)
            cell.privateButton.addTarget(self, action: #selector(changePrivacy), for: .touchUpInside)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell") as? PlayerCell else {
                return UITableViewCell()
            }
            cell.configCell(name: nameList[indexPath.row - 2], score: -1)
            if idList[indexPath.row - 2] != self.userID {
                cell.removeButton.addTarget(self, action: #selector(removePlayer), for: .touchUpInside)
                cell.removeButton.isHidden = false
            } else {
                cell.removeButton.isHidden = true
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        if let currentName = currentName, let finalGameID = finalGameID {
            let textToShare = "Join " + currentName + " in a game of Sketch It! Game Code: " + finalGameID
         
            if let myWebsite = NSURL(string: "http://www.sketchit.space/download") {
                let objectsToShare: [Any] = [textToShare, myWebsite]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.popoverPresentationController?.sourceView = sender
                self.present(activityVC, animated: true, completion: nil)
            }
        }
    }
}
