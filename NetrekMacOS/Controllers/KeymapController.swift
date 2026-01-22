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

@MainActor
class KeymapController: ObservableObject {
    var keymap: [Control: Command] = [:]

    // Dependencies - set after init
    weak var connectionManager: ServerConnectionManager?
    weak var gameStateManager: GameStateManager?

    init() {
        self.setDefaults()
        self.loadSavedKeymaps()
    }


    func setDefaults() {
        keymap = [:]
        keymap = [
            .zeroKey: .speedZero,
            .oneKey: .speedOne,
            .twoKey: .speedTwo,
            .threeKey: .speedThree,
            .fourKey: .speedFour,
            .fiveKey: .speedFive,
            .sixKey: .speedSix,
            .sevenKey: .speedSeven,
            .eightKey: .speedEight,
            .nineKey: .speedNine,
            .spacebarKey: .nothing,
            .rightParenKey: .speedTen,
            .exclamationMarkKey: .speedEleven,
            .atKey: .speedTwelve,
            .percentKey: .speedMax,
            .poundKey: .speedHalf,
            .lessThanKey: .speedDecrease,
            .greaterThanKey: .speedIncrease,
            .rightBracketKey: .raiseShields,
            .leftBracketKey: .lowerShields,
            .leftCurly: .cloakDown,
            .rightCurly: .cloakUp,
            .underscore: .tractorOn,
            .carrot: .pressorOn,
            .dollar: .tractorPressorOff,
            .aKey: .nothing,
            .bKey: .bomb,
            .cKey: .cloak,
            .dKey: .detEnemy,
            .eKey: .dockingPermission,
            .fKey: .firePlasma,
            .gKey: .nothing,
            .hKey: .nothing,
            .iKey: .information,
            .jKey: .nothing,
            .kKey: .setCourse,
            .lKey: .lockDestination,
            .mKey: .nothing,
            .nKey: .nothing,
            .oKey: .orbit,
            .pKey: .fireLaser,
            .qKey: .nothing,
            .rKey: .refit,
            .sKey: .toggleShields,
            .tKey: .fireTorpedo,
            .uKey: .raiseShields,
            .vKey: .nothing,
            .wKey: .nothing,
            .xKey: .beamDown,
            .yKey: .pressorBeam,
            .zKey: .beamUp,
            .AKey: .nothing,
            .BKey: .nothing,
            .CKey: .coup,
            .DKey: .detOwn,
            .EKey: .nothing,
            .FKey: .nothing,
            .GKey: .nothing,
            .HKey: .nothing,
            .IKey: .nothing,
            .JKey: .nothing,
            .KKey: .nothing,
            .LKey: .nothing,
            .MKey: .nothing,
            .NKey: .nothing,
            .OKey: .nothing,
            .PKey: .nothing,
            .QKey: .quitGame,
            .RKey: .repair,
            .SKey: .nothing,
            .TKey: .tractorBeam,
            .UKey: .nothing,
            .VKey: .nothing,
            .WKey: .nothing,
            .XKey: .nothing,
            .YKey: .nothing,
            .ZKey: .nothing,
            .leftMouse: .fireTorpedo,
            .otherMouse: .fireLaser,
            .rightMouse: .setCourse,
            .asteriskKey: .practiceRobot,
        ]
    }
    func setKeymap(control: Control, command: Command) {
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
                for command in Command.allCases where command.rawValue == commandString {
                    keymap[control] = command
                }
            }
        }
    }

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
            connectionManager?.send(content: cpBeam)
        case .beamDown:
            let cpBeam = MakePacket.cpBeam(state: false)
            connectionManager?.send(content: cpBeam)
        case .bomb:
            let bombState = players[me].bomb
            let cpBomb = MakePacket.cpBomb(state: !bombState )
            connectionManager?.send(content: cpBomb)
        case .cloakUp:
            guard gameStateManager?.gameState == .gameActive else { return }
            let cpCloak = MakePacket.cpCloak(state: true )
            connectionManager?.send(content: cpCloak)
            SoundController.soundController.play(sound: .shield, volume: 1.0)
        case .cloakDown:
            guard gameStateManager?.gameState == .gameActive else { return }
            let cpCloak = MakePacket.cpCloak(state: false )
            connectionManager?.send(content: cpCloak)
            SoundController.soundController.play(sound: .shield, volume: 1.0)

        case .cloak:
            guard gameStateManager?.gameState == .gameActive else { return }
            let cloakState = players[me].cloak
            let cpCloak = MakePacket.cpCloak(state: !cloakState )
            connectionManager?.send(content: cpCloak)
            SoundController.soundController.play(sound: .shield, volume: 1.0)

        case .coup:
            let cpCoup = MakePacket.cpCoup()
            connectionManager?.send(content: cpCoup)

        case .detEnemy:
            guard gameStateManager?.gameState == .gameActive else { return }
            let cpDetTorps = MakePacket.cpDetTorps()
            connectionManager?.send(content: cpDetTorps)
            SoundController.soundController.play(sound: .detonate, volume: 0.5)

        case .detOwn:
            let me = Universe.universe.me
            guard gameStateManager?.gameState == .gameActive else { return }
            for count in 0..<8 {
                let myTorpNum = UInt8(me * 8 + count)
                let cpDetMyTorps = MakePacket.cpDetMyTorps(torpNum: myTorpNum)
                connectionManager?.send(content: cpDetMyTorps)
            }
            SoundController.soundController.play(sound: .detonate, volume: 0.5)
        case .dockingPermission:
            let me = Universe.universe.me
            let cpDockperm = MakePacket.cpDockperm(state: !players[me].dockok)
            connectionManager?.send(content: cpDockperm)
        case .information:
            guard let location = location else {
                GameLogger.debug("KeymapController.execute.information location is nil...no information", category: .commands)
                return
            }
            let (closestPlayerOptional, closestPlayerDistance) = findClosestPlayer(location: location)
            let (closestPlanetOptional, closestPlanetDistance) = findClosestPlanet(location: location)
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
        case .setCourse:
            guard let location = location else {
                GameLogger.debug("KeymapController.execute.setCourse location is nil...holding steady", category: .commands)
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(location.x), destinationY: Double(location.y))
            if let cpDirection = MakePacket.cpDirection(netrekDirection: netrekDirection) {
                connectionManager?.send(content: cpDirection)
            }

        case .toggleShields:
            guard gameStateManager?.gameState == .gameActive else { return }

            let shieldsUp = players[me].shieldsUp
            if shieldsUp {
                let cpShield = MakePacket.cpShield(up: false)
                connectionManager?.send(content: cpShield)
            } else {
                let cpShield = MakePacket.cpShield(up: true)
                connectionManager?.send(content: cpShield)
            }
            SoundController.soundController.play(sound: .shield, volume: 1.0)
        case .tractorPressorOff:
            let cpTractor = MakePacket.cpTractor(on: false, playerID: 0)
            connectionManager?.send(content: cpTractor)
            let cpPressor = MakePacket.cpPressor(on: false, playerID: 0)
            connectionManager?.send(content: cpPressor)

        case .tractorOn:
            guard let targetLocation = location else {
                GameLogger.debug("KeymapController.execute.tractorBeam location is nil...cannot lock onto nothing", category: .commands)
                return
            }
            let (closestPlayerOptional, _) = findClosestPlayer(location: targetLocation)
            guard let target = closestPlayerOptional else {
                return
            }
            if target.me == true { return }
            guard target.playerId >= 0 else { return }
            guard target.playerId < 256 else { return }
            let playerID = UInt8(target.playerId)
            let cpTractor = MakePacket.cpTractor(on: true, playerID: playerID)
            connectionManager?.send(content: cpTractor)

        case .tractorBeam:
            GameLogger.debug("TractorBeam location \(String(describing: location))", category: .input)
            guard let targetLocation = location else {
                GameLogger.debug("KeymapController.execute.tractorBeam location is nil...cannot lock onto nothing", category: .commands)
                return
            }
            let (closestPlayerOptional, _) = findClosestPlayer(location: targetLocation)
            guard let target = closestPlayerOptional else {
                return
            }
            let me = Universe.universe.me
            if target.me == true { return }
            guard target.playerId >= 0 else { return }
            guard target.playerId < 256 else { return }
            let playerID = UInt8(target.playerId)
            let cpTractor = MakePacket.cpTractor(on: !players[me].tractorFlag, playerID: playerID)
            connectionManager?.send(content: cpTractor)
        case .pressorOn:
            GameLogger.debug("PressorBeam location \(String(describing: location))", category: .input)
            guard let targetLocation = location else {
                GameLogger.debug("KeymapController.execute.pressorBeam location is nil...cannot lock onto nothing", category: .commands)
                return
            }
            let (closestPlayerOptional, _) = findClosestPlayer(location: targetLocation)
            guard let target = closestPlayerOptional else {
                return
            }
            if target.me == true { return }
            guard target.playerId >= 0 else { return }
            guard target.playerId < 256 else { return }
            let playerID = UInt8(target.playerId)
            let cpPressor = MakePacket.cpPressor(on: true, playerID: playerID)
            connectionManager?.send(content: cpPressor)

        case .pressorBeam:
            GameLogger.debug("PressorBeam location \(String(describing: location))", category: .input)
            guard let targetLocation = location else {
                GameLogger.debug("KeymapController.execute.pressorBeam location is nil...cannot lock onto nothing", category: .commands)
                return
            }
            let (closestPlayerOptional, _) = findClosestPlayer(location: targetLocation)
            guard let closestPlayer = closestPlayerOptional else {
                return
            }
            let me = Universe.universe.me
            if closestPlayer.me == true { return }
            guard closestPlayer.playerId >= 0 else { return }
            guard closestPlayer.playerId < 256 else { return }
            let playerID = UInt8(closestPlayer.playerId)
            let cpPressor = MakePacket.cpPressor(on: !players[me].pressor, playerID: playerID)
            connectionManager?.send(content: cpPressor)

        case .orbit:
            let orbitState = universe.players[me].orbit
            let cpOrbit = MakePacket.cpOrbit(state: !orbitState)
            connectionManager?.send(content: cpOrbit)

        case .lowerShields:
            guard gameStateManager?.gameState == .gameActive else { return }

            let cpShield = MakePacket.cpShield(up: false)
            connectionManager?.send(content: cpShield)
            SoundController.soundController.play(sound: .shield, volume: 1.0)

        case .raiseShields:
            guard gameStateManager?.gameState == .gameActive else { return }

            let cpShield = MakePacket.cpShield(up: true)
            connectionManager?.send(content: cpShield)
            SoundController.soundController.play(sound: .shield, volume: 1.0)

        case .repair:
            guard gameStateManager?.gameState == .gameActive else { return }

            let repairState = players[me].repair
            let cpRepair = MakePacket.cpRepair(state: !repairState )
            universe.players[me].throttle = 0 // used by slider in tacticalView
            connectionManager?.send(content: cpRepair)
        case .fireLaser:
            guard gameStateManager?.gameState == .gameActive else { return }

            GameLogger.debug("FireLaser location \(String(describing: location))", category: .input)
            guard let targetLocation = location else {
                GameLogger.debug("KeymapController.execute.fireLaser location is nil...holding fire", category: .commands)
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(targetLocation.x), destinationY: Double(targetLocation.y))
            let cpLaser = MakePacket.cpLaser(netrekDirection: netrekDirection)
            connectionManager?.send(content: cpLaser)

        case .fireTorpedo:
            guard gameStateManager?.gameState == .gameActive else { return }

            GameLogger.debug("LeftMouseDown location \(String(describing: location))", category: .input)
            guard let targetLocation = location else {
                GameLogger.debug("KeymapController.execute.fireTorpedo location is nil...holding fire", category: .commands)
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(targetLocation.x), destinationY: Double(targetLocation.y))
            let cpTorp = MakePacket.cpTorp(netrekDirection: netrekDirection)
            connectionManager?.send(content: cpTorp)
        case .firePlasma:
            guard gameStateManager?.gameState == .gameActive else { return }

            GameLogger.debug("firePlasma location \(String(describing: location))", category: .input)
            guard let targetLocation = location else {
                GameLogger.debug("KeymapController.execute.firePlasma location is nil...holding fire", category: .commands)
                return
            }
            let me = Universe.universe.me
            let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(players[me].positionX), mePositionY: Double(players[me].positionY), destinationX: Double(targetLocation.x), destinationY: Double(targetLocation.y))
            let cpPlasma = MakePacket.cpPlasma(netrekDirection: netrekDirection)
            connectionManager?.send(content: cpPlasma)
        case .quitGame:
            GameLogger.debug("Quitting game", category: .commands)
            let cpQuit = MakePacket.cpQuit()
            connectionManager?.send(content: cpQuit)
        case .practiceRobot:
            GameLogger.debug("Requesting practice robot", category: .commands)
            let cpPractice = MakePacket.cpPractice()
            connectionManager?.send(content: cpPractice)
        case .lockStarbasePlanet:
            guard let lockLocation = location else {
                GameLogger.debug("KeymapController.execute.lockDestination location is nil...awaiting instructions", category: .commands)
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
                    GameLogger.debug("keymap.playerlock invalid playerID \(player.playerId)", category: .commands)
                    return
                }
                let cpPlayerLock = MakePacket.cpPlayerLock(playerID: UInt8(player.playerId))
                connectionManager?.send(content: cpPlayerLock)
            } else {
                guard let planet = closestPlanet else { return }
                guard planet.planetId > 0 && planet.planetId < 256 else {
                    GameLogger.debug("keymap.planetlock invalid planetID \(planet.planetId)", category: .commands)
                    return
                }
                let cpPlanetLock = MakePacket.cpPlanetLock(planetID: UInt8(planet.planetId))
                connectionManager?.send(content: cpPlanetLock)
            }

        case .lockDestination:
            guard let lockLocation = location else {
                GameLogger.debug("KeymapController.execute.lockDestination location is nil...awaiting instructions", category: .commands)
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
            for player in Universe.universe.players where !player.me {
                let thisPlayerDistance = abs(player.positionX - lockLocationX) + abs(player.positionY - lockLocationY)
                if thisPlayerDistance < closestPlayerDistance {
                    closestPlayerDistance = thisPlayerDistance
                    closestPlayer = player
                }
            }
            if closestPlayerDistance < closestPlanetDistance {
                // lock onto player
                guard let player = closestPlayer else { return }
                guard player.playerId >= 0 && player.playerId < 256 else {
                    GameLogger.debug("keymap.playerlock invalid playerID \(player.playerId)", category: .commands)
                    return
                }
                let cpPlayerLock = MakePacket.cpPlayerLock(playerID: UInt8(player.playerId))
                connectionManager?.send(content: cpPlayerLock)
            } else {
                guard let planet = closestPlanet else { return }
                guard planet.planetId >= 0 && planet.planetId < 256 else {
                    GameLogger.debug("keymap.planetlock invalid planetID \(planet.planetId)", category: .commands)
                    return
                }
                let cpPlanetLock = MakePacket.cpPlanetLock(planetID: UInt8(planet.planetId))
                connectionManager?.send(content: cpPlanetLock)
            }
        }
    }
    private func findClosestPlanet(location: CGPoint) -> (planet: Planet?, distance: Int) {
        var closestPlanetDistance = 10000
        var closestPlanet: Planet?
        for planet in Universe.universe.planets {
            let thisPlanetDistance = abs(planet.positionX - Int(location.x)) + abs(planet.positionY - Int(location.y))
            if thisPlanetDistance < closestPlanetDistance {
                closestPlanetDistance = thisPlanetDistance
                closestPlanet = planet
            }
        }
        return (closestPlanet, closestPlanetDistance)
    }
    private func findClosestPlayer(location: CGPoint) -> (player: Player?, distance: Int) {
        var closestPlayerDistance = 10000
        var closestPlayer: Player?
        for player in Universe.universe.players where !player.me {
            let thisPlayerDistance = abs(player.positionX - Int(location.x)) + abs(player.positionY - Int(location.y))
            if thisPlayerDistance < closestPlayerDistance {
                closestPlayerDistance = thisPlayerDistance
                closestPlayer = player
            }
        }
        return (closestPlayer, closestPlayerDistance)
    }
    func setSpeed(_ speed: Int) {
        if let cpSpeed = MakePacket.cpSpeed(speed: speed) {
            connectionManager?.send(content: cpSpeed)
        }
    }
}

// MARK: - GameCommandExecuting Conformance

extension KeymapController: GameCommandExecuting {
    // execute(_ control: Control, location: CGPoint?) already implemented above
}
