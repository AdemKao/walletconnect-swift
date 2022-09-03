//
//  ContentView.swift
//  WalletConnectExample
//
//  Created by Lev Baklanov on 12.06.2022.
//

import SwiftUI

struct ContentView: View {

    
    @StateObject
    var viewModel = ExampleViewModel()
    var web3Model = web3Provider()
    
    var body: some View {
        MainContainer(hexValue: "0")
            .environmentObject(viewModel)
            .onAppear {
                viewModel.initWalletConnect()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
