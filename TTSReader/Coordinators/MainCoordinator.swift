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
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    var coreDataManager: CoreDataManager!
    var fetchedResultsController: NSFetchedResultsController<Article>!
    weak var delegate: ListTableViewControllerDelegate?
    var currentlyBeingReadIndexPath: IndexPath?
    
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
        let vc = ListTableViewController.instantiate()
        vc.coordinator = self
        vc.delegate = self
        
        getShareUserDefaults()
        getFetchController()
        
        navigationController.pushViewController(vc, animated: false)
    }
    
    // MARK: Article functions
    
    func readArticle(_ articleToRead: Article, _ indexPath: IndexPath) {
        let vc = ReaderViewController.instantiate()
        vc.coordinator = self
        vc.article = articleToRead
        vc.activatePlaybackCommands(true)
        vc.currentArticleIndexPath = indexPath
        speechSynthesizer.delegate = vc as AVSpeechSynthesizerDelegate
        
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
                
                self.deleteShareUserDefaults(articleUrl)
                
                let alert = UIAlertController(title: "Error", message: "\(error ?? "Invalid URL") \n\n\(articleUrl)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
                self.navigationController.present(alert, animated: true, completion: nil)
                
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
        let urlArray = UserDefaults(suiteName: UserDefaultSuiteName)?.value(forKey: UserDefaultsKey) as? [String]
        guard (urlArray != nil) else {
            print("nil array")
            return
        }
        guard urlArray != [] else {
            print("Nothing in array")
            return
        }
        for url in urlArray! {
            getArticle(url)
            print(url)
        }
    }
    
    func deleteShareUserDefaults(_ urlToDelete: String) {
        var urlArray = UserDefaults(suiteName: UserDefaultSuiteName)?.value(forKey: UserDefaultsKey) as! [String]
        urlArray.remove(at: urlArray.index(of: urlToDelete)!)
        UserDefaults(suiteName: UserDefaultSuiteName)?.set(urlArray, forKey: UserDefaultsKey)
        
        animateActivityIndicator()
    }
    
    func animateActivityIndicator() {
        guard let listTableVC = navigationController.viewControllers[0] as? ListTableViewController else {
            print("First view controller isn't a ListTableViewController")
            return
        }
        
        let urlArray = UserDefaults(suiteName: UserDefaultSuiteName)?.value(forKey: UserDefaultsKey) as? [String]
        
        guard (urlArray != nil) else {
            print("nil array")
            return
        }
        
        DispatchQueue.main.async {
            if urlArray!.isEmpty {
                listTableVC.activityIndicator.stopAnimating()
            } else {
                listTableVC.activityIndicator.startAnimating()
            }
        }
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
        
        if (indexPath == currentlyBeingReadIndexPath) {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
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
    
    func checkURL(url: String ) -> Bool {
        let urlRegEx = "^http(?:s)?://(?:w{3}\\.)?(?!w{3}\\.)(?:[\\p{L}a-zA-Z0-9\\-]+\\.){1,}(?:[\\p{L}a-zA-Z]{2,})/(?:\\S*)?$"
        let urlTest = NSPredicate(format: "SELF MATCHES %@", urlRegEx)
        return urlTest.evaluate(with: url)
    }
    
    func playPauseReading(_ articleText: String, _ articleToBeRead: Article) {
        if isArticleDifferent(articleToBeRead) {
            speechSynthesizer.stopSpeaking(at: .immediate)
            
            let nextSpeechUtterance = AVSpeechUtterance(string: articleText)
            nextSpeechUtterance.rate = 0.6
            
            speechSynthesizer.speak(nextSpeechUtterance)
        } else if speechSynthesizer.isPaused {
            speechSynthesizer.continueSpeaking()
        } else if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
        } else {
            speechSynthesizer.stopSpeaking(at: .immediate)
            
             let nextSpeechUtterance = AVSpeechUtterance(string: articleText)
            nextSpeechUtterance.rate = 0.6
            
            speechSynthesizer.speak(nextSpeechUtterance)
        }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: [])
        } catch {
            print("Error with Audio playback")
        }
    }
    
    func isArticleDifferent(_ article: Article) -> Bool {
        if (fetchedResultsController.indexPath(forObject: article) == currentlyBeingReadIndexPath) {
            return false
        } else {
            return true
        }
    }
    
    func changeArticleBeingRead(_ articleBeingRead: Article) {
        
        let newArticleIndexPath = fetchedResultsController.indexPath(forObject: articleBeingRead)
        
        if currentlyBeingReadIndexPath == nil || currentlyBeingReadIndexPath != newArticleIndexPath {
            currentlyBeingReadIndexPath = newArticleIndexPath
        }
    }
}

extension MainCoordinator: ListTableViewControllerDelegate {
    func listTableViewController(_ listTableViewController: ListTableViewController, article: Article, indexPath: IndexPath) {
        readArticle(article, indexPath)
    }
}

