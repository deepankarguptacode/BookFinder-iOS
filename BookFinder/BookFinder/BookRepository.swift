//
//  BookRepository.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 14/09/25.
//

import AnyCodable
import Combine
import Foundation

protocol BookRepositoryProtocol {
    func search(title: String, page: Int) -> AnyPublisher<[Book], Error>
    func fetchDetails(for book: Book) -> AnyPublisher<Book, Error>
}

/// Coordinates between view model and API Service.
class BookRepository: BookRepositoryProtocol {
    private let api: APIServiceProtocol

    init(api: APIServiceProtocol = APIService()) {
        self.api = api
    }

    func search(title: String, page: Int) -> AnyPublisher<[Book], Error> {
        api.searchBooks(title: title, page: page)
            .tryMap { response in
                let docsWrapped = response.docs
                var results: [Book] = []
                for wrappedDoc in docsWrapped {
                    // Convert [String: AnyCodable] to [String: Any]
                    var dict: [String: Any] = [:]
                    for (key, anyCodable) in wrappedDoc {
                        dict[key] = anyCodable.value
                    }

                    // create Book object and append in results
                    if let book = Book.from(doc: dict) {
                        results.append(book)
                    }
                }
                return results
            }
            .eraseToAnyPublisher()
    }

    func fetchDetails(for book: Book) -> AnyPublisher<Book, Error> {
        api.fetchBookDetails(bookKey: book.bookKey)
            .map { detailResp -> Book in
                var updated = book
                if let desc = detailResp.description?.value {
                    updated.description = desc
                } else {
                    updated.description = nil
                }
                return updated
            }
            .eraseToAnyPublisher()
    }
}
