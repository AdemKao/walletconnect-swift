//
//  ExampleViewModel.swift
//  WalletConnectExample
//
//  Created by Lev Baklanov on 12.06.2022.
//

import Foundation
import WalletConnectSwift
import SwiftUI

class ExampleViewModel: ObservableObject {
    
    let deepLinkDelay = 0.5
    
    @Published
    var session: Session?
    @Published
    var currentWallet: Wallet?
    @Published
    var isConnecting: Bool = false
    @Published
    var isReconnecting: Bool = false
    @Published
    var walletConnect: WalletConnect?
    var pendingDeepLink: String?
    
    var walletAccount: String? {
        return session?.walletInfo!.accounts[0].lowercased()
    }
    
    var walletName: String {
        if let name = session?.walletInfo?.peerMeta.name {
            return name
        }
        return currentWallet?.name ?? ""
    }
    
    //Checking that connected to Polygon chain
    var isWrongChain: Bool {
        if let chainId = session?.walletInfo?.chainId, chainId != 97 {
            return true
        }
        return false
    }
    
    func openWallet() {
        if let wallet = currentWallet {
            if let url = URL(string: wallet.formLinkForOpen()),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    func initWalletConnect() {
        print("init wallet connect: \(walletConnect == nil)")
        if walletConnect == nil {
            walletConnect = WalletConnect(delegate: self)
            if walletConnect!.haveOldSession() {
                withAnimation {
                    isConnecting = true
                }
                walletConnect!.reconnectIfNeeded()
            }
        }
    }
    
    func connect(wallet: Wallet) {
        guard let walletConnect = walletConnect else { return }
        let connectionUrl = walletConnect.connect()
        pendingDeepLink = wallet.formWcDeepLink(connectionUrl: connectionUrl)
        currentWallet = wallet
    }
    
    func disconnect() {
        guard let session = session, let walletConnect = walletConnect else { return }
        try? walletConnect.client?.disconnect(from: session)
        withAnimation {
            self.session = nil
        }
        UserDefaults.standard.removeObject(forKey: WalletConnect.sessionKey)
    }
    
    func triggerPendingDeepLink() {
        guard let deepLink = pendingDeepLink else { return }
        pendingDeepLink = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + deepLinkDelay) {
            if let url = URL(string: deepLink), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Open app in App Store or do something else
            }
        }
    }
    
    func sendTx(to: String) {
        guard let session = session,
              let client = walletConnect?.client,
              let from = walletAccount else {
            print("nil client or session")
            return
        }
        let tx = Client.Transaction(
            from: from,
            to: to,
            data: "",
            gas: nil,
            gasPrice: nil,
            value: "0x1",
            nonce: nil,
            type: nil,
            accessList: nil,
            chainId: nil,
            maxPriorityFeePerGas: nil,
            maxFeePerGas: nil)
        do {
            try client.eth_sendTransaction(url: session.url,
                                           transaction: tx) { [weak self] response in
                self?.handleResponse(response)
            }
            DispatchQueue.main.async {
                self.openWallet()
            }
        } catch {
            print("error sending tx: \(error)")
        }
    }
    func callcontract(){
        guard let session = session,
              let client = walletConnect?.client,
              let from = walletAccount else {
            print("nil client or session")
            return
        }
        let tx = Client.Transaction(
            from: from,
            to: "0xC50EB47A26C832610abeB20ADe214B5AC0952a53",
            data: "cbdd7ff6000000000000000000000000fcc3e80c0b4261be7e0d310b16907556cc7d7155",
            gas: nil,
            gasPrice: nil,
            value: "0x1",
            nonce: nil,
            type: nil,
            accessList: nil,
            chainId: nil,
            maxPriorityFeePerGas: nil,
            maxFeePerGas: nil)
        do {
            try client.eth_sendTransaction(url: session.url,
                                           transaction: tx) { [weak self] response in
                self?.handleResponse(response)
            }
            DispatchQueue.main.async {
                self.openWallet()
            }
        } catch {
            print("error sending tx: \(error)")
        }
        
    }
    func swap(){
        guard let session = session,
              let client = walletConnect?.client,
              let from = walletAccount else {
            print("nil client or session")
            return
        }
        let tx = Client.Transaction(
            from: from,
            to: "0xa62dBC75a0A6a62A48c7548d6E94b6fA6d3326b0",
            data: "a4a79b2300000000000000000000000049af68c2306f3a5482809895e7a551adc2a98a8c0000000000000000000000006cf6028197d1cba2a7235709dcf4c4d723fd633c",
            gas: nil,
            gasPrice: nil,
            value: "0x2386f26fc10000",
            nonce: nil,
            type: nil,
            accessList: nil,
            chainId: nil,
            maxPriorityFeePerGas: nil,
            maxFeePerGas: nil)
        do {
            try client.eth_sendTransaction(url: session.url,
                                           transaction: tx) { [weak self] response in
                self?.handleResponse(response)
            }
            DispatchQueue.main.async {
                self.openWallet()
            }
        } catch {
            print("error sending tx: \(error)")
        }
        
    }
    private func handleResponse(_ response: Response) {
        DispatchQueue.main.async {
            if let error = response.error {
                print("got error sending tx: \(error)")
                return
            }
            do {
                let result = try response.result(as: String.self)
                print("got response result: \(result)")
            } catch {
                print("Unexpected response type error: \(error)")
            }
        }
    }
}

extension ExampleViewModel: WalletConnectDelegate {
    func failedToConnect() {
        DispatchQueue.main.async { [unowned self] in
            withAnimation {
                isConnecting = false
                isReconnecting = false
            }
        }
    }

    func didConnect() {
        DispatchQueue.main.async { [unowned self] in
            withAnimation {
                isConnecting = false
                isReconnecting = false
                session = walletConnect?.session
                if currentWallet == nil {
                    currentWallet = Wallets.bySession(session: session)
                }
                // Load initial web3 info here
            }
        }
    }
    
    func didSubscribe(url: WCURL) {
        triggerPendingDeepLink()
    }
    
    func didUpdate(session: Session) {
        var accountChanged = false
        if let curSession = self.session,
           let curInfo = curSession.walletInfo,
           let info = session.walletInfo,
           let curAddress = curInfo.accounts.first,
           let address = info.accounts.first,
           curAddress != address || curInfo.chainId != info.chainId {
            accountChanged = true
            do {
                let sessionData = try JSONEncoder().encode(session)
                UserDefaults.standard.set(sessionData, forKey: WalletConnect.sessionKey)
            } catch {
                print("Error saving session in update: \(error)")
            }
        }
        DispatchQueue.main.async { [unowned self] in
            withAnimation {
                self.session = session
            }
            if accountChanged {
                // Handle address change
            }
        }
    }

    func didDisconnect(isReconnecting: Bool) {
        if !isReconnecting {
            DispatchQueue.main.async { [unowned self] in
                withAnimation {
                    isConnecting = false
                    session = nil
                }
            }
        }
        DispatchQueue.main.async { [unowned self] in
            withAnimation {
                self.isReconnecting = isReconnecting
            }
        }
    }
}

