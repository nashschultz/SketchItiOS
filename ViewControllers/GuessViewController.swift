//
//  GuessViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/4/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class GuessViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var drawnImageView: UIImageView!
    @IBOutlet weak var guessTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var waitingForDrawings: UILabel!
    @IBOutlet weak var waitingTableView: UITableView!
    
    var round: Int!
    var idList: [String] = []
    var gameID: String!
    var userID: String!
    var ref: DatabaseReference!
    var count: Int!
    var isEven = false
    var bannerView: GADBannerView!
    var isHost = false
    var name: String!
    var nameList: [String] = []
    var waitingForList: [String] = []
    var evenAddition = 1
    var timerCount: Int!
    var hasSubmitted = false
    var didSubmitEarly = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()
        count = idList.count + 1
        
        if isEven == true {
            evenAddition = 0
        }
        
        submitButton.layer.cornerRadius = 20.0
        guessTextField.layer.cornerRadius = 20.0
        guessTextField.layer.borderWidth = 0
        guessTextField.clipsToBounds = true
        guessTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.adUnitID = "ca-app-pub-5912556187565517/8446111558"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        addBannerViewToView(bannerView)
        
        waitingTableView.delegate = self
        waitingTableView.dataSource = self
        waitingTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isHost == true {
            self.ref.child("games").child(gameID).child("round" + String(self.round)).removeValue()
        }
        checkForAllDrawings()
    }
    
    func checkForAllDrawings() {
        var timerForLoading = 45
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timerForLoading == 0 {
                self.ref.child("games").child(self.gameID).child("draw").removeAllObservers()
                self.waitingForDrawings.isHidden = true
                self.waitingLabel.isHidden = false
                timer.invalidate()
                self.loadImage()
            } else {
                self.waitingForDrawings.text = "Waiting for someone's drawing..." + String(timerForLoading)
                timerForLoading = timerForLoading - 1
            }
        }
        self.ref.child("games").child(self.gameID).child("draw").observe(.value) { snapshot in
            if snapshot.childrenCount == (self.idList.count + self.evenAddition) {
                print("everyone submitted")
                self.ref.removeAllObservers()
                self.waitingForDrawings.isHidden = true
                self.waitingLabel.isHidden = false
                newTimer.invalidate()
                self.loadImage()
            }
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        guessTextField.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toDraw"?:
            let destination = segue.destination as! DrawViewController
            destination.userID = self.userID
            destination.gameID = self.gameID
            destination.idList = self.idList
            destination.isHost = self.isHost
            destination.name = self.name
            destination.nameList = self.nameList
            destination.isEven = self.isEven
            destination.round = self.round + 1 // think this is the issue ?
            destination.timerCount = self.timerCount
        case "gameOver"?:
            let destination = segue.destination as! GameSummaryViewController
            destination.userID = self.userID
            destination.gameID = self.gameID
            destination.roundCount = self.round
            destination.isHost = self.isHost
            destination.name = self.name
            destination.nameList = self.nameList
            destination.idList = self.idList
            destination.isEven = self.isEven
        default:
            return
        }
    }
    
    /*func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3, animations: {
            self.viewMoveUp.frame = CGRect(x:self.viewMoveUp.frame.origin.x, y:self.viewMoveUp.frame.origin.y - 400, width:self.viewMoveUp.frame.size.width, height:self.viewMoveUp.frame.size.height);

        })
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3, animations: {
            self.viewMoveUp.frame = CGRect(x:self.viewMoveUp.frame.origin.x, y:self.viewMoveUp.frame.origin.y + 400, width:self.viewMoveUp.frame.size.width, height:self.viewMoveUp.frame.size.height);

        })
    } */
    
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
    
    
    func loadImage() {
        let storageReference = Storage.storage().reference()
        let reference = storageReference.child("games").child(self.gameID).child("round" + String(round - 1)).child("\(idList[round - 1]).jpg")
        let imageView: UIImageView = self.drawnImageView
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: nil)
        imageView.sd_setImage(with: reference)
        
        var countDownToGuess = 45
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countDownToGuess == 0 {
                if self.hasSubmitted == false {
                    self.guessTextField.text = self.name + " did not guess!"
                    self.submitGuess()
                }
            } else {
                self.waitingLabel.text = String(countDownToGuess) + "s left to guess"
                countDownToGuess = countDownToGuess - 1
            }
        }
    }
    
    @IBAction func submitGuess() {
        guessTextField.resignFirstResponder()
        if self.guessTextField.text != "" {
            self.hasSubmitted = true
            ref.child("games").child(gameID!).child("round" + String(round)).child(idList[round - 1]).setValue(self.guessTextField.text)
            self.ref.child("games").child(self.gameID).child("round" + String(self.round)).child("names").child(self.name).setValue(1)
            self.submitButton.isHidden = true
            self.guessTextField.isHidden = true
        } else {
            print("guess empty")
        }
        self.ref.child("games").child(self.gameID).child("round" + String(self.round)).observe(.value) { snapshot in
            if snapshot.childrenCount == (self.idList.count + self.evenAddition + 1) {
                print("everyone submitted")
                self.ref.child("games").child(self.gameID).child("draw").removeAllObservers()
                self.ref.child("games").child(self.gameID).child("round" + String(self.round)).removeAllObservers()
                if (self.round == self.idList.count) { // FIX THIS LINE THE NGOOD
                    self.performSegue(withIdentifier: "gameOver", sender: nil)
                } else {
                    self.performSegue(withIdentifier: "toDraw", sender: nil)
                }
            } else {
                let submittedNames = snapshot.childSnapshot(forPath: "names").value as? Dictionary<String, Any>
                self.waitingForList.removeAll()
                if submittedNames != nil {
                    for name in self.nameList {
                        if submittedNames![name] != nil {
                            print("submitted")
                        } else {
                            self.waitingForList.append(name)
                        }
                    }
                    self.waitingTableView.isHidden = false
                    self.drawnImageView.isHidden = true
                    self.waitingTableView.reloadData()
                }
            }
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.shake()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.waitingForList.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell") as? PlayerCell else {
                 return UITableViewCell()
             }
            cell.configCell(name: "Waiting for these players", score: -1)
            cell.roundedView.clipsToBounds = true
            cell.roundedView.layer.borderWidth = 2.0
            cell.roundedView.layer.borderColor = UIColor.black.cgColor
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell") as? PlayerCell else {
                return UITableViewCell()
            }
            cell.configCell(name: waitingForList[indexPath.row - 1], score: -1)
            cell.roundedView.clipsToBounds = true
            cell.roundedView.layer.borderWidth = 2.0
            cell.roundedView.layer.borderColor = UIColor.black.cgColor
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
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

