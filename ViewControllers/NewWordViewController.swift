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
    
    var name: String?
    var nameList: [String] = []
    var userID: String?
    var gameID: String?
    var ref = Database.database().reference()
    var idList: [String] = []
    var isEven = false
    var evenAddition = 1
    var randomWord: String?
    var customCount: Int?
    var bannerView: GADBannerView?
    var isHost = false
    var time = 45
    var newWordCounts = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitButton.layer.cornerRadius = 20.0
        customWordButton.layer.cornerRadius = 20.0
        wordField.layer.cornerRadius = 20.0
        hostDelete.layer.cornerRadius = 20.0
        newWordButton.layer.cornerRadius = 20.0
        wordField.clipsToBounds = true
        wordField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        view.addGestureRecognizer(tapGesture)
        
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView?.adUnitID = "ca-app-pub-5912556187565517/8446111558"
        bannerView?.rootViewController = self
        bannerView?.load(GADRequest())
        if let bannerView = bannerView {
            addBannerViewToView(bannerView)
        }
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
        
        guard let gameID = gameID else { return }
        
        if isHost == true {
            ref.child("games").child(gameID).child("round0").removeValue()
            hostDelete.isHidden = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toDraw"?:
            guard let destination = segue.destination as? DrawViewController else { return }
            destination.userID = userID
            destination.gameID = gameID
            destination.idList = idList
            destination.isEven = isEven
            destination.isHost = isHost
            destination.name = name
            destination.nameList = nameList
            destination.round = 1
            destination.timerCount = time
        default:
            return
        }
    }
    
    @IBAction func deleteGame() {
        guard let gameID = gameID else { return }
        ref.child("games").child(gameID).removeValue()
        ref.child("games").child(gameID).child("round0").removeAllObservers()
        performSegue(withIdentifier: "toLobby", sender: nil)
    }
        
    @IBAction func useCustomWord() {
        guard let customCount = customCount, let userID = userID else { return }
        if customCount > 0 {
            wordField.isUserInteractionEnabled = true
            wordField.text = ""
            wordField.backgroundColor = .white
            ref.child("users").child(userID).child("custom").setValue(customCount - 1)
            customCountLabel.text = "You have " + String(customCount - 1) + " custom tokens left"
            customWordButton.isHidden = true
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
                wordField.text = randomWord
            } catch let error {
                print("Fatal Error: \(error.localizedDescription)")
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
            print("Fatal Error: \(error.localizedDescription)")
        }
        guard let userID = userID else { return }
        ref.child("users").child(userID).child("custom").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let self = self else { return }
            self.customCount = snapshot.value as? Int
            self.customCountLabel.text = "You have " + String(self.customCount ?? 0) + " custom tokens left"
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func submitWord() {
        if wordField.text != "" {
            writeWordToDB()
            submitButton.isHidden = true
            mainLabel.adjustsFontSizeToFitWidth = true
            mainLabel.text = "Waiting for other players..."
            wordField.isHidden = true
            customCountLabel.isHidden = true
            customWordButton.isHidden = true
            wordField.resignFirstResponder()
            
            guard let gameID = gameID else { return }
            ref.child("games").child(gameID).child("round0").observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                if snapshot.childrenCount == (self.idList.count + self.evenAddition) {
                    print("everyone submitted")
                    self.ref.child("games").child(gameID).child("round0").removeAllObservers()
                    self.performSegue(withIdentifier: "toDraw", sender: nil)
                } else if !snapshot.exists() {
                    self.ref.child("games").child(gameID).child("round0").removeAllObservers()
                    self.performSegue(withIdentifier: "toLobby", sender: nil)
                }
            }
        }
    }
    
    func writeWordToDB() {
        guard let gameID = gameID, let userID = userID else { return }
        if wordField.text != "" {
            ref.child("games").child(gameID).child("round0").child(userID).setValue(wordField.text)
        } else {
            print("word is empty")
        }
    }
    
    func loadTime() {
        guard let gameID = gameID else { return }
        ref.child("games").child(gameID).child("time").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let self = self else { return }
            let newTime = snapshot.value as? Int ?? -1
            if newTime == -1 {
                self.ref.child("games").child(gameID).child("round0").removeAllObservers()
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
        ref.child("games").child(gameID!).child("players").queryOrdered(byChild: "timestamp").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let self = self else { return }
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
        guard let userID = userID else { return }
        let indexOfSelf = idList.firstIndex(of: userID)
        var before: [String] = []
        var after: [String] = []
        var beforeName: [String] = []
        var afterName: [String] = []
        var count = 0
        for id in idList {
            if count < indexOfSelf! {
                before.append(id)
            } else if count > indexOfSelf! {
                after.append(id)
            }
            count = count + 1
        }
        count = 0
        for name in nameList {
            if count < indexOfSelf! {
                beforeName.append(name)
            } else if count > indexOfSelf! {
                afterName.append(name)
            }
            count = count + 1
        }
        after.append(contentsOf: before)
        afterName.append(contentsOf: beforeName)
        idList = after
        nameList = afterName
    }
    
    func setUserAtFront() {
        guard let userID = userID else { return }
        let indexOfSelf = idList.firstIndex(of: userID)
        var before: [String] = []
        var after: [String] = []
        var beforeName: [String] = []
        var afterName: [String] = []
        var count = 0
        for id in idList {
            if count < indexOfSelf! {
                before.append(id)
            } else {
                after.append(id)
            }
            count = count + 1
        }
        count = 0
        for name in nameList {
            if count < indexOfSelf! {
                beforeName.append(name)
            } else {
                afterName.append(name)
            }
            count = count + 1
        }
        after.append(contentsOf: before)
        afterName.append(contentsOf: beforeName)
        idList = after
        nameList = afterName
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.shake()
    }
}

