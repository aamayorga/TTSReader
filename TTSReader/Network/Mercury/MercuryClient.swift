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
    
    func getWebArticle(_ url: String, completionHandlerForGetWebArticle: @escaping (_ success: Bool, _ webInfo: MercuryJSONResponse?, _ errorString: String?) -> Void) {
        
        let methodParameters = [MercuryParameterKeys.Url: url]
        let url = mercuryUrlFromParameter(methodParameters)
        
        let request = NSMutableURLRequest(url: url)
        request.setValue(MercuryHTTPHeaderValues.applicationJSON, forHTTPHeaderField: MercuryHTTPHeaderKeys.ContentType)
        request.setValue(MercuryHTTPHeaderValues.ApiKey, forHTTPHeaderField: MercuryHTTPHeaderKeys.ApiKey)
        
        networkManager.taskForGetMethod(request: request, completionHandlerForGET: { (data, error) in
            
            guard (error == nil) else {
                completionHandlerForGetWebArticle(false, nil, "Couldn't retrieve data")
                return
            }
            
            guard let data = data else {
                completionHandlerForGetWebArticle(false, nil, "No data was retrieved")
                return
            }
            
            self.convertData(data as! Data, completionHandlerForConvertData: { (results, error) in
                guard error == nil else {
                    completionHandlerForGetWebArticle(false, nil, error?.userInfo.description)
                    return
                }
                
                guard let mercuryResults = results as? MercuryJSONResponse else {
                    completionHandlerForGetWebArticle(false, nil, "Couldn't convert data to encodable Mercury data")
                    return
                }
                
                completionHandlerForGetWebArticle(true, mercuryResults, nil)
            })
        })
    }
    
    func convertData(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            parsedResult = try decoder.decode(MercuryJSONResponse.self, from: data) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertData", code: 1, userInfo: userInfo))
            return
        }
        
        completionHandlerForConvertData(parsedResult, nil)
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
