//
//  ImportViewContoller.swift
//  ethdemo
//
//  Created by Prajwal Maharjan on 3/25/19.
//  Copyright © 2019 Prajwal Maharjan. All rights reserved.
//

import UIKit

class ImportViewController: UIViewController {
    @IBOutlet weak var btnCreate: UIButton?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let mnemonic = UserDefaults.standard.string(forKey: "mnemonicKey")
        
        if !(mnemonic?.isEmpty ?? true) {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "mainViewController") as! ViewController
            self.present(newViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func onCreateWalletClicked(_ sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "mainViewController") as! ViewController
        self.present(newViewController, animated: true, completion: nil)
    }
    
    @IBAction func onImportWalletClicked(_ sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "ImportWallet", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "importWalletViewController") as! ImportWalletViewController
        self.present(newViewController, animated: true, completion: nil)
    }
}
