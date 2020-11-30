//
//  MainMenuViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/3/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase
import GoogleMobileAds

class MainMenuViewController: UIViewController, UITextFieldDelegate, GADRewardedAdDelegate, GADRewardedAdMetadataDelegate {
    
    var uid: String!
    var name: String!
    var ref: DatabaseReference!
    var rewardAd: GADRewardedAd?
    var alertController: UIAlertController!
    var customCount: Int!
    var viewDidLoadAlready: Bool!
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var customTokensButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var customTokensLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var onlineButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        rewardAd = GADRewardedAd(adUnitID: "ca-app-pub-5912556187565517/8474031712")
        rewardAd?.adMetadataDelegate = self
        rewardAd?.load(GADRequest()) { error in
            if error != nil {
            // Handle ad failed to load case.
          } else {
            // Ad successfully loaded.
          }
        }
        
        alertController = UIAlertController(title: "Custom Words", message: "Watch this video to receive 3 custom words", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Yes please", style: UIAlertAction.Style.default) {
            UIAlertAction in
                // Insert code to run on button click below
                self.runVideoAd()
        })
        alertController.addAction(UIAlertAction(title: "No thanks", style: UIAlertAction.Style.destructive, handler: nil))
        
        joinButton.layer.cornerRadius = 20.0
        createButton.layer.cornerRadius = 20.0
        customTokensButton.layer.cornerRadius = 20.0
        onlineButton.layer.cornerRadius = 20.0
        settingsButton.layer.cornerRadius = 20.0
        nameField.layer.cornerRadius = 20.0
        nameField.clipsToBounds = true
        nameField.delegate = self
        nameField.clearsOnBeginEditing = true
        
        viewDidLoadAlready = false
                
        loadNameToFile()
        initializeUser()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if viewDidLoadAlready == false {
            moveLabel()
        }
        viewDidLoadAlready = true
    }
    
    
    @IBAction func getCustomTokens() {
        self.present(alertController, animated: true, completion: nil)
    }
    
    func runVideoAd() {
        if rewardAd?.isReady == true {
           rewardAd?.present(fromRootViewController: self, delegate:self)
        }
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        loadTokens()
    }
    
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        print("dismiss")
        rewardAd = GADRewardedAd(adUnitID: "ca-app-pub-5912556187565517/8474031712")
        rewardAd!.load(GADRequest()) { error in
            if error != nil {
                print("failed to load")
          // Handle ad failed to load case.
        } else {
          // Ad successfully loaded.
        }
      }
    }
    
    
    func loadTokens() {
        self.ref.child("users").child(uid).child("custom").observeSingleEvent(of: .value, with: { (snapshot) in
            self.customCount = snapshot.value as? Int
            self.ref.child("users").child(self.uid).child("custom").setValue(self.customCount + 3)
            self.customTokensLabel.text = "You have " + String(self.customCount + 3) + " custom words"
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.shake()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toStart"?:
            let destination = segue.destination as! CreateGameViewController
            destination.currentName = self.name
            destination.userID = self.uid
        case "toJoin"?:
            let destination = segue.destination as! JoinGameViewController
            destination.currentName = self.name
            destination.userID = self.uid
        case "toFind"?:
            let destination = segue.destination as! FindGamesViewController
            destination.name = self.name
            destination.userID = self.uid
        default:
            return
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        nameField.resignFirstResponder()
    }
    
    func initializeUser() {
        Auth.auth().signInAnonymously() { (authResult, error) in
            guard let user = authResult?.user else { return }
            self.uid = user.uid
            self.ref.child("users").child(self.uid).child("custom").observeSingleEvent(of: .value, with: { (snapshot) in
                self.customCount = snapshot.value as? Int
                if self.customCount == nil {
                    self.ref.child("users").child(self.uid).child("custom").setValue(3)
                    self.customTokensLabel.text = "You have 3 custom words"
                    self.performSegue(withIdentifier: "toHelp", sender: nil)
                } else {
                    self.customTokensLabel.text = "You have " + String(self.customCount) + " custom words"
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func startGame() {
        writeNameToFile()
        if nameField.text != "" {
            self.name = nameField.text
            performSegue(withIdentifier: "toStart", sender: nil)
        } else {
            print("name empty")
            self.nameField.text = "Enter Name Here"
        }
    }
    
    @IBAction func joinGame() {
        writeNameToFile()
        if nameField.text != "" {
            self.name = nameField.text
            performSegue(withIdentifier: "toJoin", sender: nil)
        } else {
            print("name empty")
        }
    }
    
    @IBAction func findGame() {
        writeNameToFile()
        if nameField.text != "" {
            self.name = nameField.text
            performSegue(withIdentifier: "toFind", sender: nil)
        } else {
            print("name empty")
        }
    }
    
    func writeNameToFile() {
        let fileName = "name"
        let dir = try? FileManager.default.url(for: .documentDirectory,
              in: .userDomainMask, appropriateFor: nil, create: true)

        // If the directory was found, we write a file to it and read it back
        if let fileURL = dir?.appendingPathComponent(fileName).appendingPathExtension("txt") {

            // Write to the file named Test
            let outString = self.nameField.text
            do {
                try outString!.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
            }

        }
    }
    
    func loadNameToFile() {
        let fileName = "name"
        let dir = try? FileManager.default.url(for: .documentDirectory,
              in: .userDomainMask, appropriateFor: nil, create: true)

        // If the directory was found, we write a file to it and read it back
        if let fileURL = dir?.appendingPathComponent(fileName).appendingPathExtension("txt") {
            var inString = ""
            do {
                inString = try String(contentsOf: fileURL)
            } catch {
                print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
            }
            print("Read from the file: \(inString)")
            self.nameField.text = inString
        }
    }
    
     @IBAction func displayActionSheet(_ sender: Any) {
        let optionMenu = UIAlertController(title: nil, message: "Settings", preferredStyle: .actionSheet)
            
        let contactAction = (UIAlertAction(title: "Contact Us", style: .default) { UIAlertAction in
            let email = "real.ones.quiz@gmail.com"
            if let url = URL(string: "mailto:\(email)") {
              if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
              } else {
                UIApplication.shared.openURL(url)
              }
            }
        })
        let followInstagram = (UIAlertAction(title: "Follow our Instagram", style: .default) { UIAlertAction in
            let username =  "sketchitmobile" // Your Instagram Username here
            let appURL = URL(string: "instagram://user?username=\(username)")!
            let application = UIApplication.shared

            if application.canOpenURL(appURL) {
                application.open(appURL)
            } else {
                // if Instagram app is not installed, open URL inside Safari
                let webURL = URL(string: "https://instagram.com/\(username)")!
                application.open(webURL)
            }

        })
        let goToHelp = (UIAlertAction(title: "How to Play", style: .default) { UIAlertAction in
            self.performSegue(withIdentifier: "toHelp", sender: nil)
        })
        let closeAction = UIAlertAction(title: "Close", style: .cancel)

        optionMenu.addAction(contactAction)
        optionMenu.addAction(followInstagram)
        optionMenu.addAction(goToHelp)
        optionMenu.addAction(closeAction)
        
        if let popoverController = optionMenu.popoverPresentationController {
          popoverController.sourceView = self.view
          popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
          popoverController.permittedArrowDirections = []
        }
            
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func moveLabel() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.6
        animation.repeatCount = 1
        animation.autoreverses = false
        animation.fromValue = CGPoint(x: nameField.center.x - 500, y: nameField.center.y)
        animation.toValue = CGPoint(x: nameField.center.x, y: nameField.center.y)
        nameField.isHidden = false
        createButton.isHidden = false
        joinButton.isHidden = false
        logoImage.isHidden = false
        customTokensLabel.isHidden = false
        customTokensButton.isHidden = false
        settingsButton.isHidden = false
        onlineButton.isHidden = false
        nameField.layer.add(animation, forKey: "position")
        animation.fromValue = CGPoint(x: joinButton.center.x - 500, y: joinButton.center.y)
        animation.toValue = CGPoint(x: joinButton.center.x, y: joinButton.center.y)
        joinButton.layer.add(animation, forKey: "position")
        animation.fromValue = CGPoint(x: createButton.center.x + 500, y: createButton.center.y)
        animation.toValue = CGPoint(x: createButton.center.x, y: createButton.center.y)
        createButton.layer.add(animation, forKey: "position")
        animation.fromValue = CGPoint(x: onlineButton.center.x + 500, y: onlineButton.center.y)
        animation.toValue = CGPoint(x: onlineButton.center.x, y: onlineButton.center.y)
        onlineButton.layer.add(animation, forKey: "position")
        animation.fromValue = CGPoint(x: logoImage.center.x, y: logoImage.center.y - 500)
        animation.toValue = CGPoint(x: logoImage.center.x, y: logoImage.center.y)
        logoImage.layer.add(animation, forKey: "position")
        animation.fromValue = CGPoint(x: customTokensLabel.center.x, y: customTokensLabel.center.y + 300)
        animation.toValue = CGPoint(x: customTokensLabel.center.x, y: customTokensLabel.center.y)
        customTokensLabel.layer.add(animation, forKey: "position")
        animation.fromValue = CGPoint(x: customTokensButton.center.x, y: customTokensButton.center.y + 300)
        animation.toValue = CGPoint(x: customTokensButton.center.x, y: customTokensButton.center.y)
        customTokensButton.layer.add(animation, forKey: "position")
        animation.fromValue = CGPoint(x: settingsButton.center.x, y: settingsButton.center.y + 300)
        animation.toValue = CGPoint(x: settingsButton.center.x, y: settingsButton.center.y)
        settingsButton.layer.add(animation, forKey: "position")
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

extension UITextField {
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.12
        animation.repeatCount = 1
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: self.center.x, y: self.center.y + 5)
        animation.toValue = CGPoint(x: self.center.x, y: self.center.y - 15)
        layer.add(animation, forKey: "position")
    }
}
