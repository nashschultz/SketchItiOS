//
//  NewWordViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds

class NewWordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var wordField: UITextField!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var customWordButton: UIButton!
    @IBOutlet weak var customCountLabel: UILabel!
    @IBOutlet weak var hostDelete: UIButton!
    @IBOutlet weak var newWordButton: UIButton!
    @IBOutlet weak var otherLabel: UILabel!
    
    var name: String!
    var nameList: [String] = []
    var userID: String!
    var gameID: String!
    var ref: DatabaseReference!
    var idList: [String] = []
    var isEven = false
    var evenAddition = 1
    var randomWord: String!
    var customCount: Int!
    var bannerView: GADBannerView!
    var isHost = false
    var time = 45
    var newWordCounts = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        submitButton.layer.cornerRadius = 20.0
        customWordButton.layer.cornerRadius = 20.0
        wordField.layer.cornerRadius = 20.0
        hostDelete.layer.cornerRadius = 20.0
        newWordButton.layer.cornerRadius = 20.0
        wordField.clipsToBounds = true
        wordField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.adUnitID = "ca-app-pub-5912556187565517/8446111558"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        addBannerViewToView(bannerView)
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
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        wordField.resignFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadWordCount()
        loadPlayerList()
        loadTime()
        if isHost == true {
            self.ref.child("games").child(gameID).child("round0").removeValue()
            self.hostDelete.isHidden = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toDraw"?:
            let destination = segue.destination as! DrawViewController
            destination.userID = self.userID
            destination.gameID = self.gameID
            destination.idList = self.idList
            destination.isEven = self.isEven
            destination.isHost = self.isHost
            destination.name = self.name
            destination.nameList = self.nameList
            destination.round = 1
            destination.timerCount = self.time
        default:
            return
        }
    }
    
    @IBAction func deleteGame() {
        self.ref.child("games").child(self.gameID).removeValue()
        self.ref.child("games").child(self.gameID).child("round0").removeAllObservers()
        self.performSegue(withIdentifier: "toLobby", sender: nil)
    }
        
    @IBAction func useCustomWord() {
        if customCount! > 0 {
            self.wordField.isUserInteractionEnabled = true
            self.wordField.text = ""
            self.wordField.backgroundColor = .white
            self.ref.child("users").child(self.userID!).child("custom").setValue(customCount! - 1)
            self.customCountLabel.text = "You have " + String(self.customCount - 1) + " custom tokens left"
            self.customWordButton.isHidden = true
        } else {
            print("no custom tokens")
        }
    }
    
    @IBAction func newWord() {
        if newWordCounts != 2 {
            do {
                let path = Bundle.main.path(forResource: "wordlist", ofType: "txt")
                let file = try String(contentsOfFile: path!)
                let text: [String] = file.components(separatedBy: "\n")
                let gameID = Int.random(in: 0 ... text.count - 1)
                randomWord = text[gameID]
                if randomWord == "" {
                    randomWord = "turtle"
                }
                self.wordField.text = randomWord
            } catch let error {
                Swift.print("Fatal Error: \(error.localizedDescription)")
            }
            newWordCounts += 1
        }
    }
    
    func loadWordCount() {
        do {
            let path = Bundle.main.path(forResource: "wordlist", ofType: "txt")
            let file = try String(contentsOfFile: path!)
            let text: [String] = file.components(separatedBy: "\n")
            let gameID = Int.random(in: 0 ... text.count - 1)
            randomWord = text[gameID]
            if randomWord == "" {
                randomWord = "turtle"
            }
            self.wordField.text = randomWord
        } catch let error {
            Swift.print("Fatal Error: \(error.localizedDescription)")
        }
        self.ref.child("users").child(userID!).child("custom").observeSingleEvent(of: .value, with: { (snapshot) in
            self.customCount = snapshot.value as? Int
            self.customCountLabel.text = "You have " + String(self.customCount) + " custom tokens left"
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func submitWord() {
        if self.wordField.text != "" {
            writeWordToDB()
            self.submitButton.isHidden = true
            self.mainLabel.adjustsFontSizeToFitWidth = true
            self.mainLabel.text = "Waiting for other players..."
            self.wordField.isHidden = true
            self.customCountLabel.isHidden = true
            self.customWordButton.isHidden = true
            wordField.resignFirstResponder()
            self.ref.child("games").child(self.gameID).child("round0").observe(.value) { snapshot in
                if snapshot.childrenCount == (self.idList.count + self.evenAddition) {
                    print("everyone submitted")
                    self.ref.child("games").child(self.gameID).child("round0").removeAllObservers()
                    self.performSegue(withIdentifier: "toDraw", sender: nil)
                } else if !snapshot.exists() {
                    self.ref.child("games").child(self.gameID).child("round0").removeAllObservers()
                    self.performSegue(withIdentifier: "toLobby", sender: nil)
                }
            }
        }
    }
    
    func writeWordToDB() {
        if wordField.text != "" {
            ref.child("games").child(gameID!).child("round0").child(userID).setValue(self.wordField.text)
        } else {
            print("word is empty")
        }
    }
    
    func loadTime() {
        self.ref.child("games").child(gameID!).child("time").observeSingleEvent(of: .value, with: { (snapshot) in
            let newTime = snapshot.value as? Int ?? -1
            if newTime == -1 {
                self.ref.child("games").child(self.gameID).child("round0").removeAllObservers()
                self.performSegue(withIdentifier: "toLobby", sender: nil)
            } else {
                self.time = newTime // error here for ending
                self.submitButton.isHidden = false
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func loadPlayerList() {
        idList.removeAll()
        nameList.removeAll()
        self.ref.child("games").child(gameID!).child("players").queryOrdered(byChild: "timestamp").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.childrenCount % 2 == 0 {
                self.isEven = true
                self.evenAddition = 0
            }
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                self.idList.append(rest.key)
                let postDict = rest.value as? [String : AnyObject] ?? [:]
                self.nameList.append(postDict["name"] as! String)
            }
            if self.idList.count == 2 {
                self.otherLabel.text = "Playing with two people isn't recommended! More people = longer chain!"
            }
            if self.idList.count % 2 != 0 {
                self.organizeIdList()
            } else {
                self.setUserAtFront()
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func organizeIdList() {
        let indexOfSelf = self.idList.firstIndex(of: self.userID)
        var before: [String] = []
        var after: [String] = []
        var beforeName: [String] = []
        var afterName: [String] = []
        var count = 0
        for id in self.idList {
            if count < indexOfSelf! {
                before.append(id)
            } else if count > indexOfSelf! {
                after.append(id)
            }
            count = count + 1
        }
        count = 0
        for name in self.nameList {
            if count < indexOfSelf! {
                beforeName.append(name)
            } else if count > indexOfSelf! {
                afterName.append(name)
            }
            count = count + 1
        }
        after.append(contentsOf: before)
        afterName.append(contentsOf: beforeName)
        self.idList = after
        self.nameList = afterName
    }
    
    func setUserAtFront() {
        let indexOfSelf = self.idList.firstIndex(of: self.userID)
        var before: [String] = []
        var after: [String] = []
        var beforeName: [String] = []
        var afterName: [String] = []
        var count = 0
        for id in self.idList {
            if count < indexOfSelf! {
                before.append(id)
            } else {
                after.append(id)
            }
            count = count + 1
        }
        count = 0
        for name in self.nameList {
            if count < indexOfSelf! {
                beforeName.append(name)
            } else {
                afterName.append(name)
            }
            count = count + 1
        }
        after.append(contentsOf: before)
        afterName.append(contentsOf: beforeName)
        self.idList = after
        self.nameList = afterName
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.shake()
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

