//
//  web3Provider.swift
//  WalletConnectExample
//
//  Created by Adem Kao on 2022/9/3.
//

import Foundation
import web3swift

var contract:ProjectContract?

var web3:web3?
var network:Network = .ganache

var endpoint:URL?
var ethContractAddress:EthereumAddress?
var socketURI:String?

class web3Provider:ObservableObject{
    
    private let abiVersion = 2
    private var rawContract:web3.web3contract?
    private var ethContract :EthereumContract
    
    init?(){
        endpoint = URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545/")!
        ethContractAddress = EthereumAddress(contractAddress, ignoreChecksum: true)!
         do{
         web3 =  try Web3.new(endpoint!)
             
         }catch{
             
         }
        rawContract = web3!.contract(contractABI, at: ethContractAddress, abiVersion: abiVersion)!
        contract = ProjectContract()
        let at  = ethContractAddress ?? nil
        guard let c = EthereumContract(contractABI, at: at) else {return nil}
        ethContract = c
        
    }
    
    func testSending() {

        let _token = "0x6C438fc25a8C6cF787460cDe05278Ca97699Bf41"
        let _to = "0xE15115e3810866292BBa9287a2827842B222C9bE"
        let _amt = "22336524000000000000000"
        let parameters = [_token,_to,_amt] as [AnyObject]
        print(parameters)
        //let result = callContractMethod(method: .transferToken, parameters: parameters)
        //let result = buildCallMethod(method: .transferToken, parameters: parameters)

        //print(result)
    }
    
    func abitest()-> String{
        let _token = "0x6C438fc25a8C6cF787460cDe05278Ca97699Bf41"
        let _to = "0xE15115e3810866292BBa9287a2827842B222C9bE"
        let _amt = "22336524000000000000000"
        let parameters = [_token,_to,_amt] as [AnyObject]

        
        let res = ethContract.allMethods
        
        print(res)
        let method = "transferToken"
        
        let foundMethod = ethContract.methods.filter { (key, value) -> Bool in
            return key == method
        }
        let abiMethod = foundMethod[method]
    
        let encodedData = (abiMethod?.encodeParameters(parameters))!
        print("RESULT")
        /*
        encodedData.forEach { res in
            print(res, terminator:"")
        }
         */
        /*
        print("======")
        let hex = encodedData
        hex.forEach { res in
            print(res, terminator:"")
        }*/
        print("======")
        //This is the final data which walletconnect to transfer
        let hexData = encodedData as Data
        print(hexData.toHexString())
        return hexData.toHexString()
    }
        

}
