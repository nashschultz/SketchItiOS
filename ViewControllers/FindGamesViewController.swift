//
//  FindGamesViewController.swift
//  SketchIt
//
//  Created by Nash Schultz on 11/29/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import UIKit
import Firebase

class FindGamesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var gameTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    var ref: DatabaseReference!
    
    var gameList: [Game] = [Game]()
    var selectedGame: Game!
    var userID: String!
    var name: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = Database.database().reference()
        
        if #available(iOS 13.0, *) {
            // stay
        } else {
            let backArrow = UIImage(named: "backarrow.png")
            backButton.setImage(UIImage(named: "backarrow.png"), for: .normal)
        }
        
        gameTableView.delegate = self
        gameTableView.dataSource = self
        
        loadGames()
    }
    
    func loadGames() {
        //let serverValue = ServerValue.timestamp()
        let earlyDate = Calendar.current.date(
            byAdding: .minute,
          value: -10,
          to: Date())
        let serverValue = earlyDate?.timeIntervalSince1970
        self.ref.child("games").queryOrdered(byChild: "security").queryEqual(toValue: "public").observeSingleEvent(of: .value) { snapshot in
            self.gameList.removeAll()
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                let postDict = rest.value as? [String : AnyObject] ?? [:]
                let playerList = postDict["players"] as? [String : AnyObject] ?? [:]
                let totalPlayers = postDict["count"] as? Int ?? 1
                let timestamp = postDict["timestamp"] as? TimeInterval ?? TimeInterval()
                let date = Date(timeIntervalSince1970: timestamp/1000)
                
                if !playerList.isEmpty && totalPlayers < 12 && date > earlyDate! {
                    let keyValues = playerList.first?.value as? NSMutableDictionary
                    let owner = keyValues!["name"]
                    let gameID = rest.key
                    let game = Game(gameID: gameID, totalPlayers: totalPlayers, ownerName: owner as! String)
                    self.gameList.append(game)
                }
                self.gameTableView.reloadData()
            }
            
        }
    }
    
    @IBAction func dismissPage() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell") as? GameCell else {
            return UITableViewCell()
        }
        cell.configCell(game: gameList[indexPath.row])
        cell.joinButton.addTarget(self, action: #selector(joinGame), for: .touchUpInside)
        return cell
    }
    
    @objc func joinGame(_sender: AnyObject) {
        let buttonPosition = _sender.convert(CGPoint.zero, to: self.gameTableView)
        let indexPath: IndexPath? = gameTableView.indexPathForRow(at: buttonPosition)
        //selectedPost = postList[(indexPath!.row - 1)]
        selectedGame = gameList[indexPath!.row]
        self.ref.child("games").child(selectedGame.gameID).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let numPlayers = value?["count"] as? Int ?? -1
            let isLocked = value?["lock"] as? Int ?? -1
            if numPlayers != -1 && numPlayers < 12 && isLocked != 1 {
                self.performSegue(withIdentifier: "toJoin", sender: nil)
            } else {
                print("game does not exist")
            }
            }) { (error) in
                print(error.localizedDescription)
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toJoin"?:
            let destination = segue.destination as! JoinGameViewController
            destination.currentName = self.name
            destination.userID = self.userID
            destination.isRematch = true
            destination.finalGameID = self.selectedGame.gameID
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
