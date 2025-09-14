//
//  APIService.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 13/09/25.
//

import AnyCodable
import Foundation
import Combine

/// Simple API service for Open Library
protocol APIServiceProtocol {
    func searchBooks(title: String, page: Int) -> AnyPublisher<SearchResponse, Error>
}

struct SearchResponse: Codable {
    let docs: [[String: AnyCodable]]
    let numFound: Int?

    // We'll do custom decoding later in repository
    enum CodingKeys: String, CodingKey {
        case docs, numFound
    }
}

class APIService: APIServiceProtocol {
    private let baseURL = "https://openlibrary.org"
    private let session: URLSession
    private let perPageLimit: Int = 20

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchBooks(title: String, page: Int) -> AnyPublisher<SearchResponse, Error> {
        let escaped = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search.json?title=\(escaped)&limit=\(perPageLimit)&page=\(page)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: url)
            .tryMap { data, resp -> Data in
                guard let httpResponse = resp as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

