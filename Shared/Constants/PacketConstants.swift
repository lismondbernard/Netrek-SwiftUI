//
//  PacketConstants.swift
//  Netrek
//
//  Created as part of Phase 5.1: Replace Magic Numbers
//  Centralizes all packet protocol constants
//

import Foundation

/// Netrek network packet type identifiers
enum PacketType: UInt8 {
    case null = 0
    case message = 1           // SP_MESSAGE
    case playerInfo = 2        // SP_PLAYER_INFO
    case kills = 3             // SP_KILLS
    case player = 4            // SP_PLAYER
    case torpedoInfo = 5       // SP_TORP_INFO
    case torpedo = 6           // SP_TORP
    case phaser = 7            // SP_PHASER
    case plasmaInfo = 8        // SP_PLASMA_INFO
    case plasma = 9            // SP_PLASMA
    case warning = 10          // SP_WARNING
    case motd = 11             // SP_MOTD
    case you = 12              // SP_YOU
    case queue = 13            // SP_QUEUE
    case status = 14           // SP_STATUS
    case planet = 15           // SP_PLANET
    case pickOk = 16           // SP_PICKOK
    case login = 17            // SP_LOGIN
    case flags = 18            // SP_FLAGS
    case mask = 19             // SP_MASK
    case pStatus = 20          // SP_PSTATUS
    case badVersion = 21       // SP_BADVERSION
    case hostile = 22          // SP_HOSTILE
    case stats = 23            // SP_STATS
    case plLogin = 24          // SP_PL_LOGIN
    case reserved = 25         // SP_RESERVED
    case planetLoc = 26        // SP_PLANET_LOC
    case scan = 27             // SP_SCAN
    case udpReply = 28         // SP_UDP_REPLY
    case sequence = 29         // SP_SEQUENCE
    case scSequence = 30       // SP_SC_SEQUENCE
    case rsaKey = 31           // SP_RSA_KEY
    case motdPic = 32          // SP_MOTD_PIC / SP_GENERIC_32
    case shipCap = 39          // SP_SHIP_CAP
    case sReply = 40           // SP_S_REPLY
    case sMessage = 41         // SP_S_MESSAGE
    case sWarning = 42         // SP_S_WARNING
    case sYou = 43             // SP_S_YOU
    case sYouSS = 44           // SP_S_YOU_SS
    case sPlayer = 45          // SP_S_PLAYER
    case ping = 46             // SP_PING
    case sTorpedo = 47         // SP_S_TORP
    case sTorpedoInfo = 48     // SP_S_TORP_INFO
    case s8Torpedo = 49        // SP_S_8_TORP
    case sPlanet = 50          // SP_S_PLANET
    case sSequence = 56        // SP_S_SEQUENCE
    case sPhaser = 57          // SP_S_PHASER
    case sKills = 58           // SP_S_KILLS
    case sStats = 59           // SP_S_STATS
    case feature = 60          // SP_FEATURE
    case bitmap = 61           // SP_BITMAP
}

/// Fixed packet sizes for each packet type
/// -1 indicates variable-length packet
enum PacketSize {
    static let sizes: [Int] = [
        0,        // 0: NULL
        84,       // 1: SP_MESSAGE
        4,        // 2: SP_PLAYER_INFO
        8,        // 3: SP_KILLS
        12,       // 4: SP_PLAYER
        8,        // 5: SP_TORP_INFO
        12,       // 6: SP_TORP
        16,       // 7: SP_PHASER
        8,        // 8: SP_PLASMA_INFO
        12,       // 9: SP_PLASMA
        84,       // 10: SP_WARNING
        84,       // 11: SP_MOTD
        32,       // 12: SP_YOU
        4,        // 13: SP_QUEUE
        28,       // 14: SP_STATUS
        12,       // 15: SP_PLANET
        4,        // 16: SP_PICKOK
        104,      // 17: SP_LOGIN
        8,        // 18: SP_FLAGS
        4,        // 19: SP_MASK
        4,        // 20: SP_PSTATUS
        4,        // 21: SP_BADVERSION
        4,        // 22: SP_HOSTILE
        56,       // 23: SP_STATS
        52,       // 24: SP_PL_LOGIN
        20,       // 25: SP_RESERVED
        28,       // 26: SP_PLANET_LOC
        0,        // 27: SP_SCAN
        8,        // 28: SP_UDP_REPLY
        4,        // 29: SP_SEQUENCE
        4,        // 30: SP_SC_SEQUENCE
        36,       // 31: SP_RSA_KEY
        32,       // 32: SP_MOTD_PIC / SP_GENERIC_32
        0,        // 33
        0,        // 34
        0,        // 35
        0,        // 36
        0,        // 37
        0,        // 38
        60,       // 39: SP_SHIP_CAP
        8,        // 40: SP_S_REPLY
        -1,       // 41: SP_S_MESSAGE (variable)
        -1,       // 42: SP_S_WARNING (variable)
        12,       // 43: SP_S_YOU
        12,       // 44: SP_S_YOU_SS
        -1,       // 45: SP_S_PLAYER (variable)
        8,        // 46: SP_PING
        -1,       // 47: SP_S_TORP (variable)
        -1,       // 48: SP_S_TORP_INFO (variable)
        20,       // 49: SP_S_8_TORP
        -1,       // 50: SP_S_PLANET (variable)
        0,        // 51
        0,        // 52
        0,        // 53
        0,        // 54
        0,        // 55
        0,        // 56: SP_S_SEQUENCE
        -1,       // 57: SP_S_PHASER (variable)
        -1,       // 58: SP_S_KILLS (variable)
        36,       // 59: SP_S_STATS
        88,       // 60: SP_FEATURE
        524       // 61: SP_BITMAP
    ]

    /// Get the size for a given packet type
    /// - Parameter type: The packet type byte
    /// - Returns: Size in bytes, or -1 for variable-length packets, or 0 for unknown
    static func size(for type: UInt8) -> Int {
        guard type < sizes.count else { return 0 }
        return sizes[Int(type)]
    }

    /// Check if a packet type is variable-length
    static func isVariableLength(_ type: UInt8) -> Bool {
        return size(for: type) == -1
    }
}

/// Common byte offsets within packet structures
enum PacketOffsets {
    /// Offsets for SP_PLAYER packet (type 4)
    enum Player {
        static let type = 0          // UInt8
        static let playerID = 1      // UInt8
        static let direction = 2     // UInt8
        static let speed = 3         // UInt8
        static let positionX = 4     // Int32
        static let positionY = 8     // Int32
    }

    /// Offsets for SP_PLANET packet (type 15)
    enum Planet {
        static let type = 0          // UInt8
        static let planetID = 1      // UInt8
        static let owner = 2         // UInt8
        static let info = 3          // UInt8
        static let flags = 4         // Int16
        static let armies = 6        // Int16
        static let positionX = 8     // Int32 (implied from 12-byte structure)
    }

    /// Offsets for SP_TORP packet (type 6)
    enum Torpedo {
        static let type = 0          // UInt8
        static let direction = 1     // UInt8
        static let torpedoNum = 2    // UInt16
        static let positionX = 4     // Int32
        static let positionY = 8     // Int32
    }

    /// Offsets for SP_YOU packet (type 12)
    enum You {
        static let type = 0          // UInt8
        static let pad1 = 1          // UInt8
        static let playerID = 2      // UInt8
        static let pad2 = 3          // UInt8
        static let hostile = 4       // UInt32
        static let swar = 8          // UInt32
        static let armies = 12       // UInt32
        static let flags = 16        // UInt32
        static let damage = 20       // UInt32
        static let shield = 24       // UInt32
        static let fuel = 28         // UInt32
    }

    /// Offsets for SP_STATUS packet (type 14)
    enum Status {
        static let type = 0          // UInt8
        static let pad1 = 1          // UInt8
        static let tourn = 2         // UInt8
        static let pad2 = 3          // UInt8
        static let armsbomb = 4      // UInt32
        static let planets = 8       // UInt32
        static let kills = 12        // UInt32
        static let losses = 16       // UInt32
        static let time = 20         // UInt32
        static let timeProd = 24     // UInt32
    }
}
