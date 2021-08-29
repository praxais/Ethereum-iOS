//
//  ViewController.swift
//  ethdemo
//
//  Created by Prajwal Maharjan on 3/11/19.
//  Copyright © 2019 Prajwal Maharjan. All rights reserved.
//

import UIKit
import web3swift
import BigInt

class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel?
    @IBOutlet weak var edtEth: UITextField?
    @IBOutlet weak var btnSend: UIButton?
    @IBOutlet weak var labelTransaction: UILabel?
    private var keystore: BIP32Keystore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateWallet()
    }
    
    @IBAction func onSendClicked(_ sender: UIButton) {
        if keystore != nil {
            let keystoreManager = KeystoreManager([keystore!])
            if (!(edtEth?.text?.isEmpty ?? true)) {
                sendETH(keystoreManager: keystoreManager, keystore: keystore!)
            }else {
                labelTransaction?.text = "Please enter address"
            }
        }else {
            labelTransaction?.text = "Could not send ETH"
        }
    }
    
    private func generateWallet() {
        do{
            guard let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                print("Keystore not found")
                return
            }
            
            let filePath = userDir + "/keystore/key.json"
            if FileManager.default.fileExists(atPath: filePath) {
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                    print("Data not found")
                    return
                }
                guard let keystore = BIP32Keystore.init(data) else {
                    print("Failed to initialize keystore from data")
                    return
                }
                self.keystore = keystore
                
                let address = keystore.addresses?.first?.address ?? ""
                print("Address: ", address)
                
                let mnemonic = UserDefaults.standard.string(forKey: "mnemonicKey")
                
                let toDisplay = "Wallet Retrived\nMnemonic: \(String(describing: mnemonic ?? "N/A"))" + "\nAddress: \(address)"
                
                getBalance(address: address, toDisplay: toDisplay)
            } else {
                guard let mnemonic = try BIP39.generateMnemonics(bitsOfEntropy: 128) else {
                    print("Failed to create mnemonic")
                    return
                }
                
                UserDefaults.standard.set(mnemonic, forKey: "mnemonicKey")
                
                print("Mnemonic: \(mnemonic)")
                
                guard let newKeystore = try BIP32Keystore(mnemonics: mnemonic, password: "myPassword") else {
                    print("Failed to create new keystore")
                    return
                }
                
                // Then you save the created keystore to the file system:
                guard let newKeystoreJSON = try? JSONEncoder().encode(newKeystore.keystoreParams) else {
                    print("Failed to create json")
                    return
                }
                
                //create file
                let fileManager = FileManager.default
                if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let filePath =  tDocumentDirectory.appendingPathComponent("\("keystore")")
                    if !fileManager.fileExists(atPath: filePath.path) {
                        do {
                            try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            NSLog("Couldn't create document directory")
                        }
                    }
                    NSLog("Document directory is \(filePath)")
                }
                
                
                let fileCreated = FileManager.default.createFile(atPath: userDir + "/keystore/key.json", contents: newKeystoreJSON, attributes: nil)
            
            
                print("File created: \(fileCreated)")
                
                guard let firstAddress = newKeystore.addresses?.first else {
                    print("Could not find address")
                    return
                }
                
                print("wallet created")
                
                let toDisplay = "Wallet Created\nMnemonic: \(mnemonic)" + "\nAddress: \(firstAddress.address)"
                label?.text = toDisplay
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func getBalance(address: String, toDisplay: String) {
        let ethAdd = EthereumAddress(address)
        
        let balancebigint = try! Web3.InfuraRinkebyWeb3(accessToken: "2917adb69bfb4ca2b393372b5031c261").eth.getBalance(address: ethAdd!)
        
        print("Ether Balance :\(String(describing: Web3.Utils.formatToEthereumUnits(balancebigint )!))")
        
        label?.text = toDisplay + "\nEther Balance:\(String(describing: Web3.Utils.formatToEthereumUnits(balancebigint )!))"
    }
    
    private func sendETH(keystoreManager: KeystoreManager, keystore: BIP32Keystore) {
        let web3Rinkeby = Web3.InfuraRinkebyWeb3(accessToken: "2917adb69bfb4ca2b393372b5031c261")
        web3Rinkeby.addKeystoreManager(keystoreManager)
        
        var options = web3Rinkeby.transactionOptions
        options.from = keystore.addresses?.first!
        options.gasPrice = .automatic
        options.gasLimit = .automatic
        options.value = 0
        
        if let path = Bundle.main.path(forResource: "abi", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let abiSource:String = String(decoding: data, as: UTF8.self)
                
                // was testing a custom token, this can be repurposed
                if let contractRaw = web3Rinkeby.contract(abiSource, at: EthereumAddress.init("0xB6233606ec3738312c9AC62320aFFd528E8CD0d8" )),
                   let contract = contractRaw.method("transfer", parameters: [self.edtEth?.text! as AnyObject,
                                                                              BigUInt("500000000000000000000000") as AnyObject],
                                                     extraData: Data(), transactionOptions: options){
                    let estimatedGasResult:BigUInt = try! contract.estimateGas()
                    options.gasLimit = .manual(estimatedGasResult)
                    
                    let sendResultBip32 = try! contract.send(password: "", transactionOptions: options)
                    
                    print(sendResultBip32)
                    DispatchQueue.main.async {
                        self.labelTransaction?.text = "Transaction: " + (sendResultBip32.transaction.hash?.toHexString() ?? "N/A")
                    }
                    
        //
        //            switch sendResultBip32 {
        //            case .success(let r):
        //
        //            case .failure(let err):
        //                print(err)
        //                labelTransaction?.text = "Transaction: " + (err.localizedDescription)
        //            case .none:
        //                labelTransaction?.text = "Transaction failed"
        //            }
                }
              } catch {
                   // handle error
                print(error)
              }
        }
        

        
    }
}
