//
//  Coordinator.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import UIKit

protocol Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}
