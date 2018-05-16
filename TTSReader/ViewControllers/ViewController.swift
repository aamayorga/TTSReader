//
//  ViewController.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import UIKit

class ViewController: UIViewController, Storyboarded {

    weak var coordinator: MainCoordinator?
    
    @IBAction func test(_ sender: UIButton) {
        print("Test")
        let mercuryClient = MercuryClient()
        mercuryClient.getWebArticle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

