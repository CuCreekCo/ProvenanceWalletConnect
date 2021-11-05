//
//  ViewController.swift
//  ProvenanceWalletConnect
//
//  Created by Jason Davidson on 8/27/21.
//

import UIKit
import CoreData

class RootViewController: UINavigationController {

    var wcUrl: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard container != nil else {
            fatalError("This view needs a persistent container.")
        }
    }

    override var shouldAutorotate: Bool {
        false
    }
}

