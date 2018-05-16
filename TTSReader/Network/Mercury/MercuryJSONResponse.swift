//
//  MercuryJSONResponse.swift
//  TTSReader
//
//  Created by Ansuke on 5/15/18.
//  Copyright © 2018 AM. All rights reserved.
//

import Foundation

struct MercuryJSONResponse: Decodable {
    let title: String
    let content: String
    let author: String
    let datePublished: String
    let leadImageUrl: String
    let dek: String?
    let nextPageUrl: String?
    let url: String
    let domain: String
    let excerpt: String
    let wordCount: Int
    let direction: String
    let totalPages: Int
    let renderedPages: Int
}
