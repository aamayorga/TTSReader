//
//  MainCoordinator.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import CoreData
import AVFoundation
import SwiftSoup

let UserDefaultSuiteName = "group.amayorga"
let UserDefaultsKey = "temporaryUrlArray"

class MainCoordinator: NSObject, Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    var coreDataManager: CoreDataManager!
    var fetchedResultsController: NSFetchedResultsController<Article>!
    weak var delegate: ListTableViewControllerDelegate?
    
    var wordsPerMinute: Float = 235.0 {
        didSet {
            let wordsPerSecondFormatter = NumberFormatter()
            wordsPerSecondFormatter.roundingMode = .up
            wordsPerSecond = Int(wordsPerSecondFormatter.string(for: (wordsPerMinute/60.0))!)!
        }
    }
    var wordsPerSecond: Int = 0
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        getShareUserDefaults()
        getFetchController()
        
        let vc = ListTableViewController.instantiate()
        vc.coordinator = self
        vc.delegate = self
        
        navigationController.pushViewController(vc, animated: false)
    }
    
    // MARK: Article functions
    
    func readArticle(_ articleToRead: Article) {
        let vc = ReaderViewController.instantiate()
        vc.coordinator = self
        vc.article = articleToRead
        vc.activatePlaybackCommands(true)
        
        let timeComponents = estimateArticleReadTime(articleToRead.wordCount)
        
        vc.articleTimeToRead.hour = timeComponents.hour
        vc.articleTimeToRead.minute = timeComponents.minute
        vc.articleTimeToRead.second = timeComponents.second
        
        navigationController.pushViewController(vc, animated: true)
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
    
    func estimateArticleReadTime(_ wordCount: Int32) -> NSDateComponents {
        let time = Float(wordCount) / wordsPerMinute
        var hours = 0
        var minutes = Int(time)
        if minutes > 60 {
            hours = minutes / 60
            minutes = minutes - (hours * 60)
        }
        let secondsFloat = (time - Float(minutes)) * 0.60
        
        let secondsFormatter = NumberFormatter()
        secondsFormatter.maximumFractionDigits = 2
        secondsFormatter.roundingMode = .down
        let numberString = secondsFormatter.string(for: secondsFloat)
        let seconds = Int(Float(numberString!)! * 100.0)
        
        let timeComponents = NSDateComponents()
        timeComponents.hour = hours
        timeComponents.minute = minutes
        timeComponents.second = seconds
        
        return timeComponents
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
    
    func parseArticle(_ articleToParse: String) -> String {
        do {
            let doc = try SwiftSoup.parseBodyFragment(articleToParse)
            let element = try doc.text()
            return element
        } catch Exception.Error(let type, let message) {
            print(message)
        } catch {
            print("error")
        }
        
        return "Error parsing article, please try again."
    }
}

extension MainCoordinator: ListTableViewControllerDelegate {
    func listTableViewController(_ listTableViewController: ListTableViewController, article: Article) {
        readArticle(article)
    }
}
