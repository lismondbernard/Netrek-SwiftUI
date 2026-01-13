//
//  KeymapController.swift
//  Netrek
//
//  Created by Darrell Root on 3/8/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
import SwiftUI

// Control and Command enums are now in Shared/Enumerations/Control.swift

class KeymapController {
    
    #if os(macOS)
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    #elseif os(iOS)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    #endif
    
    var keymap: [Control:Command] = [:]
    
    init() {
        self.setDefaults()
        self.loadSavedKeymaps()
    }
    
    
    func setDefaults() {
        keymap = [:]
        keymap = [
            .zeroKey:.speedZero,
            .oneKey:.speedOne,
            .twoKey:.speedTwo,
            .threeKey:.speedThree,
            .fourKey:.speedFour,
            .fiveKey:.speedFive,
            .sixKey:.speedSix,
            .sevenKey:.speedSeven,
            .eightKey:.speedEight,
            .nineKey:.speedNine,
            .spacebarKey:.nothing,
            .rightParenKey:.speedTen,
            .exclamationMarkKey:.speedEleven,
            .atKey:.speedTwelve,
            .percentKey:.speedMax,
            .poundKey:.speedHalf,
            .lessThanKey:.speedDecrease,
            .greaterThanKey:.speedIncrease,
            .rightBracketKey:.raiseShields,
            .leftBracketKey:.lowerShields,
            .leftCurly:.cloakDown,
            .rightCurly:.cloakUp,
            .underscore:.tractorOn,
            .carrot:.pressorOn,
            .dollar:.tractorPressorOff,
            .aKey:.nothing,
            .bKey:.bomb,
            .cKey:.cloak,
            .dKey:.detEnemy,
            .eKey:.dockingPermission,
            .fKey:.firePlasma,
            .gKey:.nothing,
            .hKey:.nothing,
            .iKey:.information,
            .jKey:.nothing,
            .kKey:.setCourse,
            .lKey:.lockDestination,
            .mKey:.nothing,
            .nKey:.nothing,
            .oKey:.orbit,
            .pKey:.fireLaser,
            .qKey:.nothing,
            .rKey:.refit,
            .sKey:.toggleShields,
            .tKey:.fireTorpedo,
            .uKey:.raiseShields,
            .vKey:.nothing,
            .wKey:.nothing,
            .xKey:.beamDown,
            .yKey:.pressorBeam,
            .zKey:.beamUp,
            .AKey:.nothing,
            .BKey:.nothing,
            .CKey:.coup,
            .DKey:.detOwn,
            .EKey:.nothing,
            .FKey:.nothing,
            .GKey:.nothing,
            .HKey:.nothing,
            .IKey:.nothing,
            .JKey:.nothing,
            .KKey:.nothing,
            .LKey:.nothing,
            .MKey:.nothing,
            .NKey:.nothing,
            .OKey:.nothing,
            .PKey:.nothing,
            .QKey:.quitGame,
            .RKey:.repair,
            .SKey:.nothing,
            .TKey:.tractorBeam,
            .UKey:.nothing,
            .VKey:.nothing,
            .WKey:.nothing,
            .XKey:.nothing,
            .YKey:.nothing,
            .ZKey:.nothing,
            .leftMouse:.fireTorpedo,
            .otherMouse:.fireLaser,
            .rightMouse:.setCourse,
            .asteriskKey:.practiceRobot,
        ]
    }
    public func setKeymap(control: Control, command: Command) {
        self.keymap[control] = command
        UserDefaults.standard.set(command.rawValue, forKey: control.rawValue)
    }
    func resetKeymaps() {
        for control in Control.allCases {
            UserDefaults.standard.removeObject(forKey: control.rawValue)
        }
        self.setDefaults()
        UserDefaults.standard.synchronize()
    }
    func loadSavedKeymaps() {
        for control in Control.allCases {
            if let commandString = UserDefaults.standard.string(forKey: control.rawValue) {
                for command in Command.allCases {
                    if command.rawValue == commandString {
                        keymap[control] = command
                    }
                }
            }
        }
    }
    //appDelegate.keymapController.setKeymap(control: control, command: command)
    
    func execute(_ control: Control, location: CGPoint?) {
        if let command = keymap[control] {
            execute(command, location: location)
        }
    }
    func execute(_ command: Command, location: CGPoint?) {
        let universe = Universe.universe
        let players = Universe.universe.players
        let me = Universe.universe.me
        switch command {
            
        case .nothing:
            break
        case .speedZero:
            self.setSpeed(0)
        case .speedOne:
            self.setSpeed(1)
        case .speedTwo:
            self.setSpeed(2)
        case .speedThree:
            self.setSpeed(3)
        case .speedFour:
            self.setSpeed(4)
        case .speedFive:
            self.setSpeed(5)
        case .speedSix:
            self.setSpeed(6)
        case .speedSeven:
            self.setSpeed(7)
        case .speedEight:
            self.setSpeed(8)
        case .speedNine:
            self.setSpeed(9)
        case .speedTen:
            self.setSpeed(10)
        case .speedEleven:
            self.setSpeed(11)
        case .speedTwelve:
            self.setSpeed(12)
        case .speedMax:
            if let myShipType = players[me].ship, let myShipInfo = universe.shipInfo[myShipType] {
                self.setSpeed(myShipInfo.maxSpeed)
            }
        case .speedHalf:
            if let myShipType = players[me].ship, let myShipInfo = universe.shipInfo[myShipType] {
                self.setSpeed(myShipInfo.maxSpeed / 2)
            }
        case .speedIncrease:
            let currentSpeed = players[me].speed
            if currentSpeed < 12 {
                self.setSpeed(currentSpeed + 1)
            }
        case .speedDecrease:
            let currentSpeed = players[me].speed
            if currentSpeed > 0 {
                self.setSpeed(currentSpeed + 1)
            }
        case .beamUp:
            let cpBeam = MakePacket.cpBeam(state: true)
            appDelegate.reader?.send(content: cpBeam)
        case .beamDown:
            let cpBeam = MakePacket.cpBeam(state: false)
            appDelegate.reader?.send(content: cpBeam)
        case .bomb:
            let bombState = players[me].bomb
            let cpBomb = MakePacket.cpBomb(state: !bombState )
            appDelegate.reader?.send(content: cpBomb)
        case .cloakUp:
            guard appDelegate.gameState == .gameActive else { return }
            let cpCloak = MakePacket.cpCloak(state: true )
            appDelegate.reader?.send(content: cpCloak)
            SoundController.soundController.play(sound: .shield, volume: 1.0)
        case .cloakDown:
            guard appDelegate.gameState == .gameActive else { return }
            let cpCloak = MakePacket.cpCloak(state: false )
            appDelegate.reader?.send(content: cpCloak)
            SoundController.soundController.play(sound: .shield, volume: 1.0)
            
        case .cloak:
            guard appDelegate.gameState == .gameActive else { return }
            let cloakState = players[me].cloak
            let cpCloak = MakePacket.cpCloak(state: !cloakState )
            appDelegate.reader?.send(content: cpCloak)
            SoundController.soundController.play(sound: .shield, volume: 1.0)
            
        case .coup:
            let cpCoup = MakePacket.cpCoup()
            appDelegate.reader?.send(content: cpCoup)
            
        case .detEnemy:
            guard appDelegate.gameState == .gameActive else { return }
            let cpDetTorps = MakePacket.cpDetTorps()
            appDelegate.reader?.send(content: cpDetTorps)
            SoundController.soundController.play(sound: .detonate, volume: 0.5)
            
        case .detOwn:
            let me = Universe.universe.me
            guard appDelegate.gameState == .gameActive else { return }
            for count in 0..<8 {
                let myTorpNum = UInt8(me * 8 + count)
                let cpDetMyTorps = MakePacket.cpDetMyTorps(torpNum: myTorpNum)
                appDelegate.reader?.send(content: cpDetMyTorps)
            }
            SoundController.soundController.play(sound: .detonate, volume: 0.5)
        case .dockingPermission:
            let me = Universe.universe.me
            let cpDockperm = MakePacket.cpDockperm(state: !players[me].dockok)
            appDelegate.reader?.send(content: cpDockperm)
        case .information:
            guard let location = location else {
                debugPrint("KeymapController.execute.information location is nil...no information")
                return
            }
            let (closestPlayerOptional,closestPlayerDistance) = findClosestPlayer(location: location)
            let (closestPlanetOptional,closestPlanetDistance) = findClosestPlanet(location: location)
            if closestPlayerDistance < closestPlanetDistance {
                // player is closer
                guard let closestPlayer = closestPlayerOptional else { return }
                closestPlayer.showInfo()
            } else {
                // planet is closer
                guard let closestPlanet = closestPlanetOptional else { return }
                DispatchQueue.main.async {
                    closestPlanet.showInfo(team: players[me].team)
                }
            }
            
        case .refit:
            universe.gotMessage("To refit, orbit home planet and select LAUNCH SHIP menu item")
            break
        case .setCourse:
            guard let location = location else {
                debugPrint("KeymapController.execute.setCourse location is nil...holding steady")
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(location.x), destinationY: Double(location.y))
            if let cpDirection = MakePacket.cpDirection(netrekDirection: netrekDirection) {
                appDelegate.reader?.send(content: cpDirection)
            }
            
        case .toggleShields:
            guard appDelegate.gameState == .gameActive else { return }
            
            let shieldsUp = players[me].shieldsUp
            if shieldsUp {
                let cpShield = MakePacket.cpShield(up: false)
                appDelegate.reader?.send(content: cpShield)
            } else {
                let cpShield = MakePacket.cpShield(up: true)
                appDelegate.reader?.send(content: cpShield)
            }
            SoundController.soundController.play(sound: .shield, volume: 1.0)
        case .tractorPressorOff:
            let cpTractor = MakePacket.cpTractor(on: false, playerID: 0)
            appDelegate.reader?.send(content: cpTractor)
            let cpPressor = MakePacket.cpPressor(on: false, playerID: 0)
            appDelegate.reader?.send(content: cpPressor)
            
        case .tractorOn:
            guard let targetLocation = location else {
                debugPrint("KeymapController.execute.tractorBeam location is nil...cannot lock onto nothing")
                return
            }
            let (closestPlayerOptional,_) = findClosestPlayer(location: targetLocation)
            guard let target = closestPlayerOptional else {
                return
            }
            if target.me == true { return }
            guard target.playerId >= 0 else { return }
            guard target.playerId < 256 else { return }
            let playerID = UInt8(target.playerId)
            let cpTractor = MakePacket.cpTractor(on: true, playerID: playerID)
            appDelegate.reader?.send(content: cpTractor)
            
        case .tractorBeam:
            debugPrint("TractorBeam location \(String(describing: location))")
            guard let targetLocation = location else {
                debugPrint("KeymapController.execute.tractorBeam location is nil...cannot lock onto nothing")
                return
            }
            let (closestPlayerOptional,_) = findClosestPlayer(location: targetLocation)
            guard let target = closestPlayerOptional else {
                return
            }
            let me = Universe.universe.me
            if target.me == true { return }
            guard target.playerId >= 0 else { return }
            guard target.playerId < 256 else { return }
            let playerID = UInt8(target.playerId)
            let cpTractor = MakePacket.cpTractor(on: !players[me].tractorFlag, playerID: playerID)
            appDelegate.reader?.send(content: cpTractor)
        case .pressorOn:
            debugPrint("PressorBeam location \(String(describing: location))")
            guard let targetLocation = location else {
                debugPrint("KeymapController.execute.pressorBeam location is nil...cannot lock onto nothing")
                return
            }
            let (closestPlayerOptional,_) = findClosestPlayer(location: targetLocation)
            guard let target = closestPlayerOptional else {
                return
            }
            if target.me == true { return }
            guard target.playerId >= 0 else { return }
            guard target.playerId < 256 else { return }
            let playerID = UInt8(target.playerId)
            let cpPressor = MakePacket.cpPressor(on: true, playerID: playerID)
            appDelegate.reader?.send(content: cpPressor)
            
        case .pressorBeam:
            debugPrint("PressorBeam location \(String(describing: location))")
            guard let targetLocation = location else {
                debugPrint("KeymapController.execute.pressorBeam location is nil...cannot lock onto nothing")
                return
            }
            let (closestPlayerOptional,_) = findClosestPlayer(location: targetLocation)
            guard let closestPlayer = closestPlayerOptional else {
                return
            }
            let me = Universe.universe.me
            if closestPlayer.me == true { return }
            guard closestPlayer.playerId >= 0 else { return }
            guard closestPlayer.playerId < 256 else { return }
            let playerID = UInt8(closestPlayer.playerId)
            let cpPressor = MakePacket.cpPressor(on: !players[me].pressor, playerID: playerID)
            appDelegate.reader?.send(content: cpPressor)
            
        case .orbit:
            let orbitState = universe.players[me].orbit
            let cpOrbit = MakePacket.cpOrbit(state: !orbitState)
            appDelegate.reader?.send(content: cpOrbit)
            
        case .lowerShields:
            guard appDelegate.gameState == .gameActive else { return }
            
            let cpShield = MakePacket.cpShield(up: false)
            appDelegate.reader?.send(content: cpShield)
            SoundController.soundController.play(sound: .shield, volume: 1.0)
            
        case .raiseShields:
            guard appDelegate.gameState == .gameActive else { return }
            
            let cpShield = MakePacket.cpShield(up: true)
            appDelegate.reader?.send(content: cpShield)
            SoundController.soundController.play(sound: .shield, volume: 1.0)
            
        case .repair:
            guard appDelegate.gameState == .gameActive else { return }
            
            let repairState = players[me].repair
            let cpRepair = MakePacket.cpRepair(state: !repairState )
            universe.players[me].throttle = 0 // used by slider in tacticalView
            appDelegate.reader?.send(content: cpRepair)
        case .fireLaser:
            guard appDelegate.gameState == .gameActive else { return }
            
            debugPrint("FireLaser location \(String(describing: location))")
            guard let targetLocation = location else {
                debugPrint("KeymapController.execute.fireLaser location is nil...holding fire")
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(targetLocation.x), destinationY: Double(targetLocation.y))
            let cpLaser = MakePacket.cpLaser(netrekDirection: netrekDirection)
            appDelegate.reader?.send(content: cpLaser)
            
        case .fireTorpedo:
            guard appDelegate.gameState == .gameActive else { return }
            
            debugPrint("LeftMouseDown location \(String(describing: location))")
            guard let targetLocation = location else {
                debugPrint("KeymapController.execute.fireTorpedo location is nil...holding fire")
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(targetLocation.x), destinationY: Double(targetLocation.y))
            let cpTorp = MakePacket.cpTorp(netrekDirection: netrekDirection)
            appDelegate.reader?.send(content: cpTorp)
        case .firePlasma:
            guard appDelegate.gameState == .gameActive else { return }
            
            debugPrint("firePlasma location \(String(describing: location))")
            guard let targetLocation = location else {
                debugPrint("KeymapController.execute.firePlasma location is nil...holding fire")
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(targetLocation.x), destinationY: Double(targetLocation.y))
            let cpPlasma = MakePacket.cpPlasma(netrekDirection: netrekDirection)
            appDelegate.reader?.send(content: cpPlasma)
        case .quitGame:
            debugPrint("Quitting game")
            let cpQuit = MakePacket.cpQuit()
            appDelegate.reader?.send(content: cpQuit)
        case .practiceRobot:
            debugPrint("Requesting practice robot")
            let cpPractice = MakePacket.cpPractice()
            appDelegate.reader?.send(content: cpPractice)
        case .lockStarbasePlanet:
            guard let lockLocation = location else {
                debugPrint("KeymapController.execute.lockDestination location is nil...awaiting instructions")
                return
            }
            let lockLocationX = Int(lockLocation.x)
            let lockLocationY = Int(lockLocation.y)
            var closestPlanetDistance = 10000
            var closestPlanet: Planet?
            var closestPlayerDistance = 10000
            var closestPlayer: Player?
            
            for planet in Universe.universe.planets {
                let thisPlanetDistance = abs(planet.positionX - lockLocationX) + abs(planet.positionY - lockLocationY)
                if thisPlanetDistance < closestPlanetDistance {
                    closestPlanetDistance = thisPlanetDistance
                    closestPlanet = planet
                }
            }
            for player in Universe.universe.players {
                if player.ship == .starbase && player.me == false {
                    let thisPlayerDistance = abs(player.positionX - lockLocationX) + abs(player.positionY - lockLocationY)
                    if thisPlayerDistance < closestPlayerDistance {
                        closestPlayerDistance = thisPlayerDistance
                        closestPlayer = player
                    }
                }
            }
            if closestPlayerDistance < closestPlanetDistance {
                // lock onto player
                guard let player = closestPlayer else { return }
                guard player.playerId > 0 && player.playerId < 256 else {
                    debugPrint("keymap.playerlock invalid playerID \(player.playerId)")
                    return
                }
                let cpPlayerLock = MakePacket.cpPlayerLock(playerID: UInt8(player.playerId))
                appDelegate.reader?.send(content: cpPlayerLock)
            } else {
                guard let planet = closestPlanet else { return }
                guard planet.planetId > 0 && planet.planetId < 256 else {
                    debugPrint("keymap.planetlock invalid planetID \(planet.planetId)")
                    return
                }
                let cpPlanetLock = MakePacket.cpPlanetLock(planetID: UInt8(planet.planetId))
                appDelegate.reader?.send(content: cpPlanetLock)
            }
            
        case .lockDestination:
            guard let lockLocation = location else {
                debugPrint("KeymapController.execute.lockDestination location is nil...awaiting instructions")
                return
            }
            let lockLocationX = Int(lockLocation.x)
            let lockLocationY = Int(lockLocation.y)
            var closestPlanetDistance = 10000
            var closestPlanet: Planet?
            var closestPlayerDistance = 10000
            var closestPlayer: Player?
            
            for planet in Universe.universe.planets {
                let thisPlanetDistance = abs(planet.positionX - lockLocationX) + abs(planet.positionY - lockLocationY)
                if thisPlanetDistance < closestPlanetDistance {
                    closestPlanetDistance = thisPlanetDistance
                    closestPlanet = planet
                }
            }
            for player in Universe.universe.players {
                if player.me == false {
                    let thisPlayerDistance = abs(player.positionX - lockLocationX) + abs(player.positionY - lockLocationY)
                    if thisPlayerDistance < closestPlayerDistance {
                        closestPlayerDistance = thisPlayerDistance
                        closestPlayer = player
                    }
                }
            }
            if closestPlayerDistance < closestPlanetDistance {
                // lock onto player
                guard let player = closestPlayer else { return }
                guard player.playerId >= 0 && player.playerId < 256 else {
                    debugPrint("keymap.playerlock invalid playerID \(player.playerId)")
                    return
                }
                let cpPlayerLock = MakePacket.cpPlayerLock(playerID: UInt8(player.playerId))
                appDelegate.reader?.send(content: cpPlayerLock)
            } else {
                guard let planet = closestPlanet else { return }
                guard planet.planetId >= 0 && planet.planetId < 256 else {
                    debugPrint("keymap.planetlock invalid planetID \(planet.planetId)")
                    return
                }
                let cpPlanetLock = MakePacket.cpPlanetLock(planetID: UInt8(planet.planetId))
                appDelegate.reader?.send(content: cpPlanetLock)
            }
        }
    }
    private func findClosestPlanet(location: CGPoint) -> (planet: Planet?,distance: Int) {
        var closestPlanetDistance = 10000
        var closestPlanet: Planet?
        for planet in Universe.universe.planets {
            let thisPlanetDistance = abs(planet.positionX - Int(location.x)) + abs(planet.positionY - Int(location.y))
            if thisPlanetDistance < closestPlanetDistance {
                closestPlanetDistance = thisPlanetDistance
                closestPlanet = planet
            }
        }
        return (closestPlanet,closestPlanetDistance)
    }
    private func findClosestPlayer(location: CGPoint) -> (player: Player?, distance: Int) {
        var closestPlayerDistance = 10000
        var closestPlayer: Player?
        for player in Universe.universe.players {
            if player.me == false {
                let thisPlayerDistance = abs(player.positionX - Int(location.x)) + abs(player.positionY - Int(location.y))
                if thisPlayerDistance < closestPlayerDistance {
                    closestPlayerDistance = thisPlayerDistance
                    closestPlayer = player
                }
            }
        }
        return (closestPlayer, closestPlayerDistance)
    }
    func setSpeed(_ speed: Int) {
        if let cpSpeed = MakePacket.cpSpeed(speed: speed) {
            appDelegate.reader?.send(content: cpSpeed)
        }
    }

}

// MARK: - GameCommandExecuting Conformance

extension KeymapController: GameCommandExecuting {
    // execute(_ control: Control, location: CGPoint?) already implemented above
}
