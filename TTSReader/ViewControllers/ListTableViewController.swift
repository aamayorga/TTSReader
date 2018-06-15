//
//  ListTableViewController.swift
//  TTSReader
//
//  Created by Ansuke on 5/17/18.
//  Copyright © 2018 AM. All rights reserved.
//

import UIKit
import CoreData

protocol ListTableViewControllerDelegate: class {
    func listTableViewController(_ listTableViewController: ListTableViewController, article: Article, indexPath: IndexPath)
}

class ListTableViewController: UITableViewController, Storyboarded {
    
    let cellIdentifier = "articleCell"
    let activityIndicator = UIActivityIndicatorView()
    
    weak var coordinator: MainCoordinator?
    
    public weak var delegate: ListTableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        let barButton = UIBarButtonItem(customView: activityIndicator)
        let addArticleButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addArticle))
        
        self.navigationItem.leftBarButtonItems = [barButton]
        
        activityIndicator.activityIndicatorViewStyle = .gray
        coordinator?.animateActivityIndicator()
        
        coordinator?.fetchedResultsController.delegate = self
    }
    
    @objc func addArticle() {
        coordinator?.addArticle()
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let article = coordinator?.fetchedResultsController.object(at: indexPath)
        self.delegate?.listTableViewController(self, article: article!, indexPath: indexPath)
        print(article?.title ?? "No title")
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return coordinator?.fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coordinator?.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let article = coordinator?.fetchedResultsController.object(at: indexPath)

        cell.textLabel?.text = article?.title
        
        return cell
    }
 
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            coordinator?.deleteArticle(indexPath)
        } else if editingStyle == .insert {
            
        }
    }
}

extension ListTableViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
