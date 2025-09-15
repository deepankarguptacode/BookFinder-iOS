//
//  BookDetailViewModel.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 15/09/25.
//

import Foundation
import Combine
import CoreData

class BookDetailViewModel: ObservableObject {
    @Published var book: Book
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: BookRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(book: Book,
         repository: BookRepositoryProtocol = BookRepository()) {
        self.book = book
        self.repository = repository
    }

    func loadDetailsIfNeeded() {
        guard book.description == nil else { return }
        isLoading = true
        repository.fetchDetails(for: book)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updated in
                self?.book = updated
            }
            .store(in: &cancellables)
    }

}
