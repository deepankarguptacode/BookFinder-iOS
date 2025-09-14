//
//  SearchViewModel.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 13/09/25.
//

import Foundation
import Combine
import CoreData
import SwiftUI

class SearchViewModel: ObservableObject {
    
    @Published var query = ""
    @Published var books = [Book]()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var page: Int = 1
    @Published var hasMore: Bool = true

    private var cancellables = Set<AnyCancellable>()
    private let repository: BookRepositoryProtocol

    init(repository: BookRepositoryProtocol = BookRepository()) {
        self.repository = repository

        // Debounce search queries so we don't call API on every keystroke
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetAndSearch()
            }
            .store(in: &cancellables)
    }

    func resetAndSearch() {
        page = 1
        books = []
        hasMore = true
        fetchNextPage()
    }

    func fetchNextPage() {
        guard !isLoading,
              !query.trimmingCharacters(in: .whitespaces).isEmpty,
              hasMore else {
            return
        }
        isLoading = true
        errorMessage = nil

        repository.search(title: query, page: page)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let e):
                    self?.errorMessage = e.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [weak self] new in
                guard let self = self else { return }
                if new.isEmpty {
                    hasMore = false
                } else {
                    books.append(contentsOf: new)
                    page += 1
                }
            }
            .store(in: &cancellables)
    }

    // Pull to refresh
    func refresh() {
        resetAndSearch()
    }
}
