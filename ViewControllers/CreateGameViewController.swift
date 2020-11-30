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
    
    var ref: DatabaseReference!
    var finalGameID: String!
    var nameList: [String] = []
    var idList: [String] = []
    var currentName: String!
    var userID: String!
    var isRematch = false
    var time = 45
    var privacy = "private"

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()
        
        startButton.layer.cornerRadius = 20.0
        shareButton.layer.cornerRadius = 20.0
        
        self.playerTableView.delegate = self
        self.playerTableView.dataSource = self
        
        self.playerTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        if #available(iOS 13.0, *) {
            // stay
        } else {
            backButton.setImage(UIImage(named: "backarrow.png"), for: .normal)
        }
        
        createGame()
        // Do any additional setup after loading the view.
    }
    
    func createGame() {
        if isRematch == false {
            let gameID = String(Int.random(in: 100000 ... 999999))
            self.ref.child("games").child(gameID).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
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
        self.gameCodeLabel.text = self.finalGameID
        if isRematch == true {
            self.ref.child("games").child(self.finalGameID).updateChildValues(["count": 1,
                                                                      "round" : 0,
                                                                      "lock" : 0,
                                                                      "timestamp" : Firebase.ServerValue.timestamp(),
                                                                      "players" : [self.userID : [
                                                                                                  "name": self.currentName as Any,
                                                                                                  "timestamp": Firebase.ServerValue.timestamp()]]
            ])
        } else {
            self.ref.child("games").child(self.finalGameID).setValue(["count": 1,
                                                                      "security" : "private",
                                                                      "round" : 0,
                                                                      "lock" : 0,
                                                                      "timestamp" : Firebase.ServerValue.timestamp(),
                                                                      "players" : [self.userID : [
                                                                                                  "name": self.currentName as Any,
                                                                        "timestamp": Firebase.ServerValue.timestamp()]]
            ])
        }
        self.ref.child("games").child(self.finalGameID).child("players").observe(.value) { snapshot in
            self.nameList.removeAll()
            self.idList.removeAll()
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                let postDict = rest.value as? [String : AnyObject] ?? [:]
                self.nameList.append(postDict["name"] as! String)
                self.idList.append(rest.key)
            }
            self.playerTableView.reloadData()
            self.playerLabel.text = "Players: " + String(self.nameList.count) + "/12"
            self.ref.child("games").child(self.finalGameID).child("count").setValue(self.nameList.count)
            if self.nameList.count > 1 {
                self.startButton.alpha = 1.0
                self.startButton.setTitle("Start Game", for: .normal)
                self.startButton.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc func removePlayer(_sender: AnyObject) {
        print("clicked")
        let buttonPosition = _sender.convert(CGPoint.zero, to: self.playerTableView)
        let indexPath: IndexPath? = playerTableView.indexPathForRow(at: buttonPosition)
        //selectedPost = postList[(indexPath!.row - 1)]
        self.ref.child("games").child(self.finalGameID).child("players").child(idList[indexPath!.row - 1]).removeValue()
    }
    
    @IBAction func startTheGame() {
        if startButton.alpha == 1.0 {
            self.ref.child("games").child(self.finalGameID).updateChildValues(["lock": 1, "time" : self.time])
            self.ref.child("games").child(self.finalGameID).child("players").removeAllObservers()
            self.performSegue(withIdentifier: "toGame", sender: nil)
        }
    }
    
    @IBAction func leaveGame() {
        self.ref.removeAllObservers()
        if finalGameID != nil && isRematch == false {
            self.ref.child("games").child(self.finalGameID!).removeValue()
        } else if finalGameID != nil && isRematch == true {
            self.ref.child("games").child(finalGameID).child("players").removeValue()
            self.ref.child("games").child(finalGameID).child("lock").setValue(1)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toGame"?:
            let destination = segue.destination as! NewWordViewController
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
            self.time = 45
        } else if _sender.titleLabel!.text == "30s" {
            self.time = 30
        } else if _sender.titleLabel!.text == "60s" {
            self.time = 60
        }
    }
    
    @objc func changePrivacy(_sender: UIButton) {
        if _sender.titleLabel!.text == "Public" {
            self.privacy = "public"
            self.ref.child("games").child(self.finalGameID).updateChildValues(["security": self.privacy])
        } else if _sender.titleLabel!.text == "Private" {
            self.privacy = "private"
            self.ref.child("games").child(self.finalGameID).updateChildValues(["security": self.privacy])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nameList.count + 2
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
        if self.currentName != nil && self.finalGameID != nil {
            let textToShare = "Join " + self.currentName + " in a game of Sketch It! Game Code: " + self.finalGameID!
         
            if let myWebsite = NSURL(string: "http://www.sketchit.space/download") {
                let objectsToShare: [Any] = [textToShare, myWebsite]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.popoverPresentationController?.sourceView = sender
                self.present(activityVC, animated: true, completion: nil)
            }
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
