//
//  JoinGameViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class JoinGameViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var gameField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var gameLabel: UILabel!
    @IBOutlet weak var playerTableView: UITableView!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var waitingForGameLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var ref: DatabaseReference!
    var finalGameID: String!
    var nameList: [String] = []
    var currentName: String!
    var userID: String!
    var isRematch = false
    var isInGame = false

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)

        self.playerTableView.delegate = self
        self.playerTableView.dataSource = self
        
        self.playerTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        doneButton.layer.cornerRadius = 20.0
        gameField.layer.cornerRadius = 20.0
        shareButton.layer.cornerRadius = 20.0
        gameField.clipsToBounds = true
        gameField.delegate = self
        gameField.clearsOnBeginEditing = true
        
        if #available(iOS 13.0, *) {
            // stay
        } else {
            let backArrow = UIImage(named: "backarrow.png")
            backButton.setImage(UIImage(named: "backarrow.png"), for: .normal)
        }
        
        checkIfRematch()
        // Do any additional setup after loading the view.
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        gameField.resignFirstResponder()
    }
    
    func checkIfRematch() {
        if isRematch == true {
            self.ref.child("games").child(self.finalGameID!).child("players").child(self.userID).setValue([
                "name": self.currentName as Any,
                "timestamp": Firebase.ServerValue.timestamp() ])
            self.getPlayerList()
            self.playerTableView.isHidden = false
            self.playerLabel.isHidden = false
            self.waitingForGameLabel.isHidden = false
            self.shareButton.isHidden = false
            self.doneButton.isHidden = true
            self.gameLabel.isHidden = true
            self.gameField.isUserInteractionEnabled = false
            self.gameField.text = self.finalGameID
        }
    }
    
    @IBAction func submitGameCode() {
            gameField.resignFirstResponder()
            if self.gameField.text != "" {
                let gameID = self.gameField.text
                self.ref.child("games").child(gameID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    let numPlayers = value?["count"] as? Int ?? -1
                    let isLocked = value?["lock"] as? Int ?? -1
                    if numPlayers != -1 && numPlayers < 12 && isLocked != 1 {
                        self.finalGameID = gameID
                        self.ref.child("games").child(gameID!).child("players").child(self.userID).setValue([
                            "name": self.currentName as Any,
                            "timestamp": Firebase.ServerValue.timestamp()
                        ])
                        self.getPlayerList()
                        self.playerTableView.isHidden = false
                        self.playerLabel.isHidden = false
                        self.waitingForGameLabel.isHidden = false
                        self.shareButton.isHidden = false
                        self.doneButton.isHidden = true
                        self.gameLabel.isHidden = true
                        self.gameField.isUserInteractionEnabled = false
                    } else {
                        print("game does not exist")
                        self.gameField.text = "Game does not exist"
                    }
                    }) { (error) in
                        print(error.localizedDescription)
                    }
            }
    }
    
    func getPlayerList() {
        self.ref.child("games").child(self.finalGameID).child("players").observe(.value) { snapshot in
            self.nameList.removeAll()
            self.isInGame = false
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                let postDict = rest.value as? [String : AnyObject] ?? [:]
                self.nameList.append(postDict["name"] as! String)
                if rest.key == self.userID {
                    self.isInGame = true
                }
            }
            if self.isInGame == false {
                print("kicked or deleted")
                self.ref.child("games").child(self.finalGameID).child("lock").removeAllObservers()
                self.ref.child("games").child(self.finalGameID).child("players").removeAllObservers()
                self.dismiss(animated: true, completion: nil)
            }
            self.playerTableView.reloadData()
            self.playerLabel.text = "Players: " + String(self.nameList.count) + "/12"
            print(self.nameList)
        }
        self.ref.child("games").child(self.finalGameID).child("lock").observe(.value) { snapshot in
            let lockValue = snapshot.value as? Int ?? -1
            if lockValue == 1 {
                print("GAME STARTED")
                self.ref.child("games").child(self.finalGameID).child("lock").removeAllObservers()
                self.ref.child("games").child(self.finalGameID).child("players").removeAllObservers()
                self.performSegue(withIdentifier: "toGame", sender: nil)
            } else if lockValue == -1 {
                self.ref.child("games").child(self.finalGameID).child("lock").removeAllObservers()
                self.ref.child("games").child(self.finalGameID).child("players").removeAllObservers()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func leaveGame() {
        if self.finalGameID != nil {
            self.ref.child("games").child(self.finalGameID).child("lock").removeAllObservers()
            self.ref.child("games").child(self.finalGameID).child("players").removeAllObservers()
            self.ref.child("games").child(self.finalGameID!).child("players").child(self.userID).removeValue()
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
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nameList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell") as? PlayerCell else {
            return UITableViewCell()
        }
        cell.configCell(name: nameList[indexPath.row], score: -1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.shake()
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        let textToShare = "Join " + self.currentName + " in a game of Sketch It! Game Code: " + self.finalGameID!
     
        if let myWebsite = NSURL(string: "http://www.sketchit.space/download") {
            let objectsToShare: [Any] = [textToShare, myWebsite]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }

}

