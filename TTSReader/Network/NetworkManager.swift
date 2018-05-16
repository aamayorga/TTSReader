//
//  NetworkManager.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import Foundation

class NetworkManager: NSObject {
    func taskForGetMethod(request: NSMutableURLRequest, completionHandlerForGET: @escaping (_ results: AnyObject?, _ error: Error?) -> Void) {
        
        let urlTask = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            guard error == nil else {
                sendError("Error cound not complete GET request.")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Status code returned non-2XX code.")
                return
            }
            
            guard let data = data else {
                sendError("No data returned by request.")
                return
            }
            
            completionHandlerForGET(data as AnyObject, nil)
        }
        
        urlTask.resume()
    }
}
