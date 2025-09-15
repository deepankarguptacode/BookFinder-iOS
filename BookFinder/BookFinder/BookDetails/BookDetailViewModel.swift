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
    @Published var isSaved: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: BookRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    private let managedContext: NSManagedObjectContext

    init(book: Book,
         repository: BookRepositoryProtocol = BookRepository(),
         context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.book = book
        self.repository = repository
        self.managedContext = context
        checkSavedState()
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

    private func checkSavedState() {
        let req: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", book.id)
        if let count = try? managedContext.count(for: req), count > 0 {
            isSaved = true
        } else {
            isSaved = false
        }
    }

    // CoreData save / delete
    func toggleSave() {
        if isSaved {
            unsave()
        } else {
            save()
        }
    }

    private func save() {
        let saved = SavedBook(context: managedContext)
        saved.id = book.id
        saved.title = book.title
        saved.author = book.authorText
        saved.coverURL = book.coverURL?.absoluteString
        saved.publishYear = Int64(book.firstPublishYear ?? 0)
        saved.bookDescription = book.description
        saved.createdAt = Date()
        do {
            try managedContext.save()
            isSaved = true
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    private func unsave() {
        let req: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", book.id)
        do {
            let items = try managedContext.fetch(req)
            for item in items { managedContext.delete(item) }
            try managedContext.save()
            isSaved = false
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }
}
