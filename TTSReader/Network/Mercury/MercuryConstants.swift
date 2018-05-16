//
//  MercuryConstants.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import Foundation

extension MercuryClient {
    struct MercuryURLComponents {
        static let ApiScheme = "https"
        static let ApiHost = "mercury.postlight.com"
        static let ApiPath = "/parser"
    }
    
    struct MercuryHTTPHeaderKeys {
        static let ContentType = "Content-Type"
        static let ApiKey = "x-api-key"
    }
    
    struct MercuryHTTPHeaderValues {
        static let applicationJSON = "application/json"
        static let ApiKey = MercuryClient.ApiKey
    }
    
    struct MercuryParameterKeys {
        static let Url = "url"
    }
    
    struct MercuryParameterValues {
        // Website URL
        static let webURL = "https://www.theverge.com/2018/5/1/17307690/marvel-avengers-infinity-war-ending"
    }
}
