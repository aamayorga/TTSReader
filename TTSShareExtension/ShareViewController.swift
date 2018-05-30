//
//  ShareViewController.swift
//  TTSShareExtension
//
//  Created by Ansuke on 5/17/18.
//  Copyright © 2018 AM. All rights reserved.
//

import UIKit
import MobileCoreServices

class ShareViewController: UIViewController {
    
    let urlArrayKey = "temporaryUrlArray"
    let shareDefaults = UserDefaults(suiteName: "group.amayorga")
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.perform(#selector(leave), with: nil, afterDelay: 1.5)
    }
    
    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)
        let item: NSExtensionItem = self.extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider: NSItemProvider = item.attachments?.first as! NSItemProvider

        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, error) in
                let url = url as! URL
                self.setUpArray()
                self.saveUrl(url: url)
            }
        } else {
            print("Didn't find URL", itemProvider)
            self.label.text = "Error!"
            self.activityIndicator.stopAnimating()
        }
    }
    
    func setUpArray() {
        guard (shareDefaults?.value(forKey: urlArrayKey)) != nil else {
            let urlArray: [String] = []
            shareDefaults?.setValue(urlArray, forKey: urlArrayKey)
            return
        }
    }
    
    func saveUrl(url: URL) {
        var urlArray = shareDefaults?.value(forKey: urlArrayKey) as! [String]
        urlArray.append(url.absoluteString)
        shareDefaults?.setValue(urlArray, forKey: urlArrayKey)
        printUrl()
        label.text = "Saved!"
        activityIndicator.stopAnimating()
    }
    
    func printUrl() {
        let urlArray = shareDefaults?.value(forKey: urlArrayKey) as! [String]
        for url in urlArray {
            print(url)
        }
    }

    @objc func leave() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: { (false) in
            print("I don't feel so good...")
        })
    }
}

//MARK: NSItemProvider check
extension NSItemProvider {
    var isURL: Bool {
        return hasItemConformingToTypeIdentifier(kUTTypeURL as String)
    }
}
