//
//  MainCoordinator.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import UIKit
import CoreData

let UserDefaultSuiteName = "group.amayorga"
let UserDefaultsKey = "temporaryUrlArray"

class MainCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    var coreDataManager: CoreDataManager!
    var fetchedResultsController: NSFetchedResultsController<Article>!
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        getShareUserDefaults()
        getFetchController()
        
        let vc = ListTableViewController.instantiate()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: false)
        
        print(fetchedResultsController?.fetchedObjects)
    }
    
    func getArticle(_ articleUrl: String) {
        MercuryClient().getWebArticle(articleUrl) { (success, data, error) in
            print(success)
            guard success else {
                print(error!)
                return
            }
            self.saveArticle(data!)
            self.deleteShareUserDefaults(articleUrl)
        }
    }
    
    func getShareUserDefaults() {
        let urlArray = UserDefaults(suiteName: UserDefaultSuiteName)?.value(forKey: UserDefaultsKey) as! [String]
        guard urlArray != [] else {
            print("Nothing in array")
            return
        }
        for url in urlArray {
            getArticle(url)
            print(url)
        }
    }
    
    func deleteShareUserDefaults(_ urlToDelete: String) {
        var urlArray = UserDefaults(suiteName: UserDefaultSuiteName)?.value(forKey: UserDefaultsKey) as! [String]
        urlArray.remove(at: urlArray.index(of: urlToDelete)!)
        UserDefaults(suiteName: UserDefaultSuiteName)?.set(urlArray, forKey: UserDefaultsKey)
    }
    
    func getFetchController() {
        fetchedResultsController = coreDataManager.setUpFetchResultsController()
        
        guard fetchedResultsController != nil else {
            fatalError("Could not fetch results controller")
        }
    }
    
    func saveArticle(_ articleToSave: MercuryJSONResponse) {
        let article = Article(context: coreDataManager.viewContext)
        
        article.title = articleToSave.title
        article.content = articleToSave.content
        article.author = articleToSave.author
        article.datePublished = articleToSave.datePublished
        article.leadImageUrl = articleToSave.leadImageUrl
        article.dek = articleToSave.dek
        article.nextPageUrl = articleToSave.nextPageUrl
        article.url = articleToSave.url
        article.domain = articleToSave.domain
        article.excerpt = articleToSave.excerpt
        article.wordCount = Int32(articleToSave.wordCount)
        article.direction = articleToSave.direction
        article.totalPages = Int16(articleToSave.totalPages)
        article.renderedPages = Int16(articleToSave.renderedPages)
        article.displayOrder = Int32(fetchedResultsController.fetchedObjects!.count)
        
        coreDataManager.saveContext()
    }
    
    func deleteArticle(_ indexPath: IndexPath) {
        let articleToDelete = fetchedResultsController.object(at: indexPath)
        coreDataManager.viewContext.delete(articleToDelete)
        coreDataManager.saveContext()
    }
}
