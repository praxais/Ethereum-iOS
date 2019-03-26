//
//  ImportWalletViewController.swift
//  ethdemo
//
//  Created by Prajwal Maharjan on 3/25/19.
//  Copyright © 2019 Prajwal Maharjan. All rights reserved.
//

import UIKit
import web3swift

class ImportWalletViewController: UIViewController {
    @IBOutlet weak var keyField: UITextField?
    
    @IBAction func onImportClicked(_ sender: UIButton) {
        if (!(keyField?.text?.isEmpty ?? true)) {
            do{
                let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                
                UserDefaults.standard.set(keyField?.text ?? "", forKey: "mnemonicKey")
                
                print("Mnemonic: \(keyField?.text ?? "")")
                
                guard let newKeystore = try BIP32Keystore(mnemonics: keyField?.text ?? "", password: "myPassword") else {
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
                FileManager.default.createFile(atPath: userDir + "/keystore/key.json", contents: newKeystoreJSON, attributes: nil)
                
                guard let firstAddress = newKeystore.addresses?.first else {
                    print("Could not find address")
                    return
                }
                
                print("wallet created, address: \(firstAddress)")
                
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "mainViewController") as! ViewController
                self.present(newViewController, animated: true, completion: nil)
            }catch{
                print(error.localizedDescription)
            }
        }
    }
}
