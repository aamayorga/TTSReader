//
//  MercuryClient.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import Foundation

class MercuryClient {
    
    let networkManager = NetworkManager()
    
    func getWebArticle(/*_ url: String*/) {
        let methodParameters = [MercuryParameterKeys.Url: MercuryParameterValues.webURL]
        let url = mercuryUrlFromParameter(methodParameters)
        
        let request = NSMutableURLRequest(url: url)
        request.setValue(MercuryHTTPHeaderValues.applicationJSON, forHTTPHeaderField: MercuryHTTPHeaderKeys.ContentType)
        request.setValue(MercuryHTTPHeaderValues.ApiKey, forHTTPHeaderField: MercuryHTTPHeaderKeys.ApiKey)
        
        networkManager.taskForGetMethod(request: request, completionHandlerForGET: { (result, error) in
            print(result!)
        })
    }
    
    
    
    fileprivate func mercuryUrlFromParameter(_ parameters: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = MercuryURLComponents.ApiScheme
        components.host = MercuryURLComponents.ApiHost
        components.path = MercuryURLComponents.ApiPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: value)
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
