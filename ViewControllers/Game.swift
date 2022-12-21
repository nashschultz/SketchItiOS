//
//  Game.swift
//  SketchIt
//
//  Created by Nash Schultz on 11/29/20.
//  Copyright © 2020 Nash Schultz. All rights reserved.
//

import Foundation

class Game {
    private var _gameID: String
    private var _totalPlayers: Int
    private var _ownerName: String
    
    var gameID: String {
        return _gameID
    }
    
    var totalPlayers: Int {
        return _totalPlayers
    }
    
    var ownerName: String {
        return _ownerName
    }
    
    init(gameID: String, totalPlayers: Int, ownerName: String) {
        _gameID = gameID
        _totalPlayers = totalPlayers
        _ownerName = ownerName
    }
}
