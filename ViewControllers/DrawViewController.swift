//
//  DrawViewController.swift
//  Pictionary
//
//  Created by Nash Schultz on 5/3/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class DrawViewController: UIViewController {
    
    var lastPoint = CGPoint.zero
    var color = UIColor.black
    var brushWidth: CGFloat = 5.0
    var opacity: CGFloat = 1.0
    var swiped = false
    var tempImage: UIImage!
    var dotCount = 1
    
    var gameID: String!
    var userID: String!
    var idList: [String] = []
    var ref: DatabaseReference!
    var isEven = false
    var currentWordUserID: String!
    var path: String!
    var round: Int!
    var isHost = false
    var name: String!
    var nameList: [String] = []

    var timerCount: Int!
    var tempTimerCount: Int!
    var drawTimer: Timer!
    var didSubmitEarly = false
    
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var strokeButton: UIButton!
    @IBOutlet weak var selectedColor: UIImageView!
    @IBOutlet weak var trashCan: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var iconsBar: UIView!
    @IBOutlet weak var bigWord: UILabel!
    
    var randomWord = "turtle"

    override func viewDidLoad() {
        super.viewDidLoad()
        toolbarView.layer.cornerRadius = 20.0
        toolbarView.clipsToBounds = true
        toolbarView.layer.borderWidth = 2.0
        toolbarView.layer.borderColor = UIColor.black.cgColor
        
        iconsBar.layer.cornerRadius = 20.0
        iconsBar.clipsToBounds = true
        iconsBar.layer.borderWidth = 2.0
        iconsBar.layer.borderColor = UIColor.black.cgColor
        
        ref = Database.database().reference()
        // Do any additional setup after loading the view.
        
        if #available(iOS 13.0, *) {
            let largeConfig = UIImage.SymbolConfiguration(pointSize: (10), weight: .bold, scale: .large)
            let largeBoldDoc = UIImage(systemName: "circle.fill", withConfiguration: largeConfig)
            selectedColor.image = largeBoldDoc
        } else {
            // Fallback on earlier versions
            selectedColor.image = UIImage(named: "whitedot.png")
            strokeButton.setImage(UIImage(named: "dot1.png"), for: .normal)
            undoButton.setImage(UIImage(named: "backarrow.png"), for: .normal)
            trashCan.setImage(UIImage(named: "trashcan.png"), for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadWord()
        if isHost == true {
            self.ref.child("games").child(self.gameID).child("draw").removeValue()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toGuess"?:
            let destination = segue.destination as! GuessViewController
            destination.userID = self.userID
            destination.gameID = self.gameID
            destination.idList = self.idList
            destination.round = self.round + 1
            destination.isEven = self.isEven
            destination.isHost = self.isHost
            destination.name = self.name
            destination.nameList = self.nameList
            destination.timerCount = self.timerCount
        default:
            return
        }
    }
    
    @IBAction func adjustStrokeWidth() {
        if brushWidth != 20 {
            self.brushWidth += 5
            if #available(iOS 13.0, *) {
                let largeConfig = UIImage.SymbolConfiguration(pointSize: (5 + brushWidth), weight: .bold, scale: .large)
                let largeBoldDoc = UIImage(systemName: "circle.fill", withConfiguration: largeConfig)
                self.strokeButton.setImage(largeBoldDoc, for: .normal)
            } else {
                // Fallback on earlier versions
                self.dotCount += 1
                let newDot = UIImage(named: "dot" + String(self.dotCount) + ".png")
                self.strokeButton.setImage(newDot, for: .normal)
            }
        } else {
            self.brushWidth = 5
            if #available(iOS 13.0, *) {
                let largeConfig = UIImage.SymbolConfiguration(pointSize: (10), weight: .bold, scale: .large)
                let largeBoldDoc = UIImage(systemName: "circle.fill", withConfiguration: largeConfig)
                self.strokeButton.setImage(largeBoldDoc, for: .normal)
            } else {
                // Fallback on earlier versions
                self.dotCount = 1
                self.strokeButton.setImage(UIImage(named: "dot1.png"), for: .normal)
            }
        }
    }
    
    func loadWord() {
            let roundString = String(self.round - 1)
            /*if self.isEven == true && self.round == 1 {
                self.path = "round" + roundString
                self.round = 
                self.currentWordUserID = self.userID
                self.ref.child("games").child(self.gameID!).child(self.path).child(self.userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    let word = snapshot.value as? String ?? "Draw anything"
                    // GOT THE WORD
                    self.wordLabel.text = "You are drawing: " + word
                }) { (error) in
                    print(error.localizedDescription)
                }
            } else { */
                self.path = "round" + roundString
                self.currentWordUserID = self.idList[self.round - 1]
        
                do {
                    let path = Bundle.main.path(forResource: "wordlist", ofType: "txt")
                    let file = try String(contentsOfFile: path!)
                    let text: [String] = file.components(separatedBy: "\n")
                    let gameID = Int.random(in: 0 ... text.count - 1)
                    randomWord = text[gameID]
                    if randomWord == "" {
                        randomWord = "turtle"
                    }
                } catch let error {
                    Swift.print("Fatal Error: \(error.localizedDescription)")
                }
        
                self.ref.child("games").child(self.gameID!).child(self.path).child(self.currentWordUserID).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    
                    
                    let word = snapshot.value as? String ?? self.randomWord
                    // GOT THE WORD
                    self.wordLabel.text = "You are drawing: " + word
                    self.bigWord.text = word
                }) { (error) in
                    print(error.localizedDescription)
                }
            //}
            self.drawingTime()
    }
    
    func animateWord() {
        UIView.animate(withDuration: 0.5, delay: 0.2, options: .curveEaseOut, animations: {
            self.wordLabel.transform = CGAffineTransform(scaleX: 2.5, y: 2.5) //Scale label area
            self.bigWord.transform = CGAffineTransform(scaleX: 3.5, y: 3.5)
            //self.wordLabel.transform = CGAffineTransform(translationX: 0, y: -200)
        }, completion: { finished in

        })
        UIView.animate(withDuration: 0.5, delay: 0.9, options: .curveEaseOut, animations: {
            self.wordLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) //Scale label area
            self.bigWord.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            //self.wordLabel.transform = CGAffineTransform(translationX: 0, y: -200)
        }, completion: { finished in
            self.bigWord.isHidden = true
        })
    }
    
    /*@IBAction func doneEarly() {
        didSubmitEarly = true
        if !self.swiped {
            self.drawLine(from: self.lastPoint, to: self.lastPoint)
        }
        self.tempImage = self.mainImageView.image
        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(self.mainImageView.frame.size)
        self.mainImageView.image?.draw(in: self.view.bounds, blendMode: .normal, alpha: 1.0)
        self.tempImageView?.image?.draw(in: self.view.bounds, blendMode: .normal, alpha: self.opacity)
        self.mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.tempImageView.image = nil
        self.uploadImage()
    } */
    
    func drawingTime() {
        animateWord()
        tempTimerCount = self.timerCount
        drawTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.tempTimerCount == 0 {
                    timer.invalidate()
                    if !self.swiped {
                        self.drawLine(from: self.lastPoint, to: self.lastPoint)
                    }
                    self.tempImage = self.mainImageView.image
                    // Merge tempImageView into mainImageView
                    UIGraphicsBeginImageContext(self.mainImageView.frame.size)
                    self.mainImageView.image?.draw(in: self.view.bounds, blendMode: .normal, alpha: 1.0)
                    self.tempImageView?.image?.draw(in: self.view.bounds, blendMode: .normal, alpha: self.opacity)
                    self.mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    self.tempImageView.image = nil
                    self.uploadImage()
            } else {
                self.timerLabel.text = "Time left: " + String(self.tempTimerCount)
                self.tempTimerCount = self.tempTimerCount - 1
            }
                
        }
    }
    
    func uploadImage() {
        if mainImageView.image != nil {
            if let optimizedImageData = self.mainImageView.image!.jpegData(compressionQuality: 0.6)
            {
                self.uploadProfileImage(imageData: optimizedImageData)
            }
        } else if tempImageView.image != nil {
            if let optimizedImageData = self.tempImageView.image!.jpegData(compressionQuality: 0.6)
            {
                self.uploadProfileImage(imageData: optimizedImageData)
            }
        } else {
            print("set temp image here")
            if let optimizedImageData = UIImage(named: "tempwhite.png")!.jpegData(compressionQuality: 0.6)
            {
                self.uploadProfileImage(imageData: optimizedImageData)
            }
        }
    }
    
    func uploadProfileImage(imageData: Data)
    {
        let storageReference = Storage.storage().reference()
        let profileImageRef = storageReference.child("games").child(self.gameID!).child("round" + String(round)).child("\(self.currentWordUserID!).jpg")
        
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/jpeg"
        
        let uploadTask = profileImageRef.putData(imageData, metadata: uploadMetaData) { (uploadedImageMeta, error) in
           
            
            if error != nil
            {
                print("Error took place \(String(describing: error?.localizedDescription))")
                return
            } else {
                                
                print("Meta data of uploaded image \(String(describing: uploadedImageMeta))")
            }
        }
        
        uploadTask.observe(.success) { snapshot in
            self.ref.child("games").child(self.gameID!).child("draw").child(self.userID!).setValue(1)
            self.performSegue(withIdentifier: "toGuess", sender: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      guard let touch = touches.first else {
        return
      }
      swiped = false
      lastPoint = touch.location(in: view)
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
      UIGraphicsBeginImageContext(view.frame.size)
      guard let context = UIGraphicsGetCurrentContext() else {
        return
      }
      tempImageView.image?.draw(in: view.bounds)
        
      context.move(to: fromPoint)
      context.addLine(to: toPoint)
      
      context.setLineCap(.round)
      context.setBlendMode(.normal)
      context.setLineWidth(brushWidth)
      context.setStrokeColor(color.cgColor)
      
      context.strokePath()
      
      tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
      tempImageView.alpha = opacity
      UIGraphicsEndImageContext()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
      guard let touch = touches.first else {
        return
      }

      swiped = true
      let currentPoint = touch.location(in: view)
      drawLine(from: lastPoint, to: currentPoint)
        
      lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLine(from: lastPoint, to: lastPoint)
        }
        tempImage = mainImageView.image
        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(mainImageView.frame.size)
        mainImageView.image?.draw(in: view.bounds, blendMode: .normal, alpha: 1.0)
        tempImageView?.image?.draw(in: view.bounds, blendMode: .normal, alpha: opacity)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
    }
    
    @IBAction func changeColor(_sender: UIButton) {
        selectedColor.center = _sender.center
        color = _sender.backgroundColor!
    }
    
    @IBAction func undoPrevious() {
        mainImageView.image = tempImage
    }
    
    @IBAction func clearCanvas() {
        mainImageView.image = nil
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
