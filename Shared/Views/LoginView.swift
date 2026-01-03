//
//  LoginView.swift
//  Netrek2
//
//  Created by Darrell Root on 6/1/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    #if os(macOS)
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    #elseif os(iOS)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    #endif
    
    @State var loginName: String
    @State var loginPassword: String
    @State var userInfo: String
    @ObservedObject var loginInformationController: LoginInformationController
    
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
    var body: some View {
        VStack {
            #if os(iOS)
            HStack {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Select Server")
                }.foregroundColor(.blue)
                    .font(.title)
                    .onTapGesture {
                        self.appDelegate.gameScreen = .noServerSelected
                }
                Spacer()
            }
            #endif
            ScrollView {
                Picker(selection: $loginInformationController.loginAuthenticated, label: EmptyView()) {
                    Text("            Play as Guest            ").tag(false)
                    Text("Specify Netrek Server Account").tag(true)
                }.pickerStyle(SegmentedPickerStyle())
                    .padding()
                
                HStack {
                    VStack {
                        ForEach (0..<17) {_ in
                            Text("")
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("We recommend new players play as guest.  If you specify a login name and UserInfo they will be visible to other players.")
                        Text("")
                        Text("If you don't already have an account on the server, one will be created for you (assuming your name and username are unique).  Make sure to remember your password.  This netrek client saves your network password in your keychain.")
                        Spacer()
                    }
                    VStack(alignment: .leading){
                        HStack {
                            Text("Name")
                            TextField(loginInformationController.loginName,text: $loginName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        HStack {
                            Text("Password")
                            SecureField(loginInformationController.securePassword,text: $loginPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        HStack {
                            Text("UserInfo")
                            TextField(loginInformationController.userInfo, text: $userInfo)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        Button("Save Login Information") {
                            self.saveInfo()
                        }.disabled(self.validInfo ? false : true)
                            .cornerRadius(8)
                            .padding([.top,.bottom])
                        Button("Clear Login Information") {
                            self.loginName = ""
                            self.loginPassword = ""
                            self.userInfo = ""
                            self.loginInformationController.loginAuthenticated = false
                            self.saveInfo()
                        }
                        .cornerRadius(8)
                        Text("Warning: Netrek servers use an old network protocol which is out of our control.  The password is not encrypted on the network.  We recommend you use a different/unique password than other accounts for your Netrek login.")
                            .padding(.top)
                        Spacer()
                    }
                }
            }
        }.padding(8)
    }
	
    func saveInfo() {
        self.loginInformationController.updateName(name: self.loginName)
        self.loginInformationController.updatePassword(password: self.loginPassword)
        self.loginInformationController.updateUserInfo(userInfo: self.userInfo)
    }
}
