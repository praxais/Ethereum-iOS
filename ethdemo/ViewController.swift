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
                
                FileManager.default.createFile(atPath: userDir + "/keystore/key.json", contents: newKeystoreJSON, attributes: nil)
                
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
        let balancebigint = Web3.InfuraRinkebyWeb3(accessToken: "fc3b28083a234976a573818de16fd142").eth.getBalance(address: ethAdd!).value
        print("Ether Balance :\(String(describing: Web3.Utils.formatToEthereumUnits(balancebigint ?? 0)!))")
        
        label?.text = toDisplay + "\nEther Balance:\(String(describing: Web3.Utils.formatToEthereumUnits(balancebigint ?? 0)!))"
    }
    
    private func sendETH(keystoreManager: KeystoreManager, keystore: BIP32Keystore) {
        let web3Rinkeby = Web3.InfuraRinkebyWeb3(accessToken: "fc3b28083a234976a573818de16fd142")
        web3Rinkeby.addKeystoreManager(keystoreManager)
        
        var options = Web3Options.defaultOptions()
        options.from = keystore.addresses?.first!
        options.gasLimit = BigUInt(21000)
        options.value = Web3.Utils.parseToBigUInt("0.0004", units: .eth)
        
        let contract = web3Rinkeby.contract(Web3.Utils.coldWalletABI, at: EthereumAddress.init(edtEth?.text ?? "0x7299192CD862c9c5345cC47a2Ef24807436009b0"))?.method(options: options)
        let estimatedGasResult = contract?.estimateGas(options: nil)
        guard case .success(let estimatedGas)? = estimatedGasResult else {return}
        
        options.gasLimit = estimatedGas
        
        let sendResultBip32 = contract?.send(password: "myPassword")
        
        switch sendResultBip32 {
        case .success(let r)?:
            print(r)
            labelTransaction?.text = "Transaction: " + (r.transaction.hash?.toHexString() ?? "N/A")
        case .failure(let err)?:
            print(err)
            labelTransaction?.text = "Transaction: " + (err.localizedDescription)
        case .none:
            labelTransaction?.text = "Transaction failed"
        }
    }
}
