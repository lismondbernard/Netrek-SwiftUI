//
//  Globals.swift
//  Netrek
//
//  Created by Darrell Root on 3/1/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//
//  DEPRECATED: This file is being phased out in favor of GameConstants and PacketConstants
//

import Foundation

// MARK: - Deprecated Constants
// These are maintained for backward compatibility but should be replaced with GameConstants/PacketConstants

@available(*, deprecated, message: "Use GameConstants.updateRate instead")
let UPDATE_RATE = 20  // number of attempts to update per second

@available(*, deprecated, message: "Use GameConstants.nameLength instead")
let NAME_LEN = 16

@available(*, deprecated, message: "Use GameConstants.maxPlanets instead")
let MAXPLANETS = 40

@available(*, deprecated, message: "Use GameConstants.maxPlayers instead")
let MAXPLAYERS = 32

@available(*, deprecated, message: "Use GameConstants.socketVersion instead")
let SOCKVERSION: UInt8 = 4

@available(*, deprecated, message: "Use GameConstants.udpVersion instead")
let UDPVERSION: UInt8 = 10

@available(*, deprecated, message: "Use GameConstants.wellKnownServers instead")
let WELLKNOWNSERVERS = [
    "pickled.netrek.org",
    "continuum.us.netrek.org"
]

@available(*, deprecated, message: "Use GameConstants.defaultServerPort instead")
let WELLKNOWNPORT = 2592

#if DEBUG
@available(*, deprecated, message: "Use GameConstants.debugAutoConnectLocalhost instead")
let DEBUG_AUTO_CONNECT_LOCALHOST = true

@available(*, deprecated, message: "Use GameConstants.debugServer instead")
let DEBUG_SERVER = "localhost"
#endif

@available(*, deprecated, message: "Use PacketSize.sizes instead")
let PACKET_SIZES: [Int] = [
    0,        // NULL
    84,        // SP_MESSAGE
    4,        // SP_PLAYER_INFO
    8,        // SP_KILLS
    12,        // SP_PLAYER
    8,        // SP_TORP_INFO
    12,        // SP_TORP
    16,        // SP_PHASER
    8,        // SP_PLASMA_INFO
    12,        // SP_PLASMA
    84,        // SP_WARNING
    84,        // SP_MOTD
    32,        // SP_YOU
    4,        // SP_QUEUE
    28,        // SP_STATUS
    12,        // SP_PLANET
    4,        // SP_PICKOK
    104,        // SP_LOGIN
    8,        // SP_FLAGS
    4,        // SP_MASK
    4,        // SP_PSTATUS
    4,        // SP_BADVERSION
    4,        // SP_HOSTILE
    56,        // SP_STATS
    52,        // SP_PL_LOGIN
    20,        // SP_RESERVED
    28,        // SP_PLANET_LOC
    0,        // SP_SCAN
    8,        // SP_UDP_REPLY
    4,        // SP_SEQUENCE
    4,        // SP_SC_SEQUENCE
    36,        // SP_RSA_KEY
    32,        // SP_MOTD_PIC  // error is SP_GENERIC_32
    0,        // 33
    0,        // 34
    0,        // 35
    0,        // 36
    0,        // 37
    0,        // 38
    60,        // SP_SHIP_CAP
    8,        // SP_S_REPLY
    -1,        // SP_S_MESSAGE
    -1,        // SP_S_WARNING
    12,        // SP_S_YOU
    12,        // SP_S_YOU_SS
    -1,        // SP_S_PLAYER
    8,        // SP_PING
    -1,        // SP_S_TORP
    -1,        // SP_S_TORP_INFO
    20,        // SP_S_8_TORP
    -1,        // SP_S_PLANET
    0,        // 51
    0,        // 52
    0,        // 53
    0,        // 54
    0,        // 55
    0,        // SP_S_SEQUENCE
    -1,        // SP_S_PHASER
    -1,        // SP_S_KILLS
    36,        // SP_S_STATS
    88,        // SP_FEATURE
    524        // SP_BITMAP
]





