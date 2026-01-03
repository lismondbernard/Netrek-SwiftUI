//
//  LoginInformationController.swift
//  Netrek
//
//  Created by Darrell Root on 3/14/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import SwiftUI
import Security

// The ViewController stuff here may no longer be necessary, but static functions still used 5/5/20

class LoginInformationController: ObservableObject {

    @Published var loginName: String = ""
    @Published var loginPassword: String = ""
    @Published var userInfo: String = ""
    @Published var loginAuthenticated = false {
        didSet {
            self.updateLoginAuthenticated(loginAuthenticated: loginAuthenticated)
        }
    }
    var validInfo: Bool {
        if loginName.count == 0 {
            return false
        }
        if loginPassword.count == 0 {
            return false
        }
        if userInfo.count == 0 {
            return false
        }
        return true
    }

    
    var securePassword: String {
        var retval = ""
        for _ in 0 ..< loginPassword.count {
            retval.append("•")
        }
        return retval
    }


    let defaults = UserDefaults.standard
    static let keychainService = "NetrekService"
    static let keychainAccount = "NetrekAccount"

    init() {
        if let loginName = defaults.string(forKey: LoginDefault.loginName.rawValue) {
            self.loginName = loginName
        }
        if let userInfo = defaults.string(forKey: LoginDefault.userInfo.rawValue) {
            self.userInfo = userInfo
        }
        self.loginAuthenticated = defaults.bool(forKey: LoginDefault.loginAuthenticated.rawValue)
            
        if let loginPassword = LoginInformationController.getPasswordKeychain() {
            self.loginPassword = loginPassword
        }
    }
    
    func updateName(name: String) {
        self.loginName = name
        if name != "" {
            defaults.setString(string: name, forKey: LoginDefault.loginName.rawValue)
        } else {
            defaults.removeObject(forKey: LoginDefault.loginName.rawValue)
        }
    }
    func updatePassword(password: String) {
        self.loginPassword = password
        if password != "" {
            KeychainService.removePassword(service: LoginInformationController.keychainService, account: LoginInformationController.keychainAccount)
            KeychainService.savePassword(service: LoginInformationController.keychainService, account: LoginInformationController.keychainAccount, data: password)
        } else {
            KeychainService.removePassword(service: LoginInformationController.keychainService, account: LoginInformationController.keychainAccount)
        }
    }
    static func getPasswordKeychain() -> String? {
        return KeychainService.loadPassword(service: keychainService, account: keychainAccount)
    }
    func updateUserInfo(userInfo: String) {
        self.userInfo = userInfo
        if userInfo != "" {
            defaults.setString(string: userInfo, forKey: LoginDefault.userInfo.rawValue)
        } else {
            defaults.removeObject(forKey: LoginDefault.userInfo.rawValue)
        }
    }
    func updateLoginAuthenticated(loginAuthenticated: Bool) {
        if loginAuthenticated {
            defaults.set(true, forKey: LoginDefault.loginAuthenticated.rawValue)
        } else {
            defaults.set(false, forKey: LoginDefault.loginAuthenticated.rawValue)
        }
    }
}
