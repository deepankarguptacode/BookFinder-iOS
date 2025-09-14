//
//  Book.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 14/09/25.
//

import Foundation

/// Book model to represent a Book.
struct Book: Identifiable, Codable, Equatable {
    // We'll use the work key (e.g. "/works/OL468516W") as id
    let id: String
    let title: String
    let authors: [String]
    let coverId: Int?
    let firstPublishYear: Int?
    let workKey: String // same as id but clearer
    var description: String?

    var coverURL: URL? {
        guard let cid = coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(cid)-M.jpg")
    }

    var authorText: String {
        authors.joined(separator: ", ")
    }

    /// Creates an object of type Book from given JSON object.
    static func from(doc: [String: Any]) -> Book? {
        guard let key = doc["key"] as? String,
              let title = doc["title"] as? String else { return nil }
        let authorArr = doc["author_name"] as? [String] ?? []
        let coverId = doc["cover_i"] as? Int
        let year = doc["first_publish_year"] as? Int
        return Book(id: key,
                    title: title,
                    authors: authorArr,
                    coverId: coverId,
                    firstPublishYear: year,
                    workKey: key,
                    description: nil
        )
    }

}
