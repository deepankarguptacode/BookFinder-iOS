//
//  SearchViewModelTests.swift
//  BookFinderTests
//
//  Created by Deepankar Gupta on 15/09/25.
//

import XCTest
import Combine
import CoreData
@testable import BookFinder

// Mock repository for testing
class MockBookRepository: BookRepositoryProtocol {

    var searchResult: Result<[Book], Error> = .success([])
    var searchCallCount = 0
    var lastSearchTitle: String?
    var lastSearchPage: Int?

    func search(title: String, page: Int) -> AnyPublisher<[Book], Error> {
        searchCallCount += 1
        lastSearchTitle = title
        lastSearchPage = page

        switch searchResult {
        case .success(let books):
            return Just(books)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func fetchDetails(for book: BookFinder.Book) -> AnyPublisher<BookFinder.Book, any Error> {
        let book = Book(id: "",
                    title: "",
                    authors: [""],
                    coverId: 1,
                    firstPublishYear: 2005,
                    bookKey: "")
        return Just(book)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()


    }
}

// Mock Book model for testing
struct MockBook: Hashable {
    let id: String
    let title: String
}

// Assuming your Book model conforms to these protocols
extension MockBook {
    static func createMockBooks(count: Int, prefix: String = "Book") -> [Book] {
        // This would need to be adapted based on your actual Book model
        // For now, returning empty array - you'll need to create actual Book instances
        return []
    }
}

class SearchViewModelTests: XCTestCase {

    var viewModel: SearchViewModel!
    var mockRepository: MockBookRepository!
    var cancellables: Set<AnyCancellable>!
    var sampleBook: Book!

    override func setUp() {
        super.setUp()
        mockRepository = MockBookRepository()
        viewModel = SearchViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
        sampleBook = Book(id: "123",
                    title: "Test Book",
                    authors: ["James"],
                    coverId: 1,
                    firstPublishYear: 2005,
                    bookKey: "123")
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables = nil
        sampleBook = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.query, "")
        XCTAssertTrue(viewModel.books.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.page, 1)
        XCTAssertTrue(viewModel.hasMore)
    }

    // MARK: - Search Query Tests

    func testSearchQueryDebounce() {
        let expectation = XCTestExpectation(description: "Debounced search should be called")

        // Mock some books to return
        mockRepository.searchResult = .success([])

        // Set up expectation for search to be called
        mockRepository.searchResult = .success([])

        // Change query multiple times quickly
        viewModel.query = "H"
        viewModel.query = "Ha"
        viewModel.query = "Har"
        viewModel.query = "Harr"
        viewModel.query = "Harry"

        // Wait for debounce + a bit extra
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Should only have been called once due to debouncing
            XCTAssertEqual(self.mockRepository.searchCallCount, 1)
            XCTAssertEqual(self.mockRepository.lastSearchTitle, "Harry")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testEmptyQueryDoesNotTriggerSearch() {
        mockRepository.searchResult = .success([])

        viewModel.query = ""

        // Wait a bit to ensure debounce would have triggered
        let expectation = XCTestExpectation(description: "Empty query should not trigger search")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.mockRepository.searchCallCount, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testWhitespaceOnlyQueryDoesNotTriggerSearch() {
        mockRepository.searchResult = .success([])

        viewModel.query = "   "

        let expectation = XCTestExpectation(description: "Whitespace query should not trigger search")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.mockRepository.searchCallCount, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Fetch Next Page Tests

    func testFetchNextPageSuccess() {
        let expectation = XCTestExpectation(description: "Fetch next page should succeed")

        // Mock successful response
        mockRepository.searchResult = .success([sampleBook])

        viewModel.query = "Harry Potter"

        // Wait for debounced search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNil(self.viewModel.errorMessage)
            XCTAssertEqual(self.viewModel.page, 2) // Should increment after successful fetch
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetchNextPageWithEmptyResult() {
        let expectation = XCTestExpectation(description: "Empty result should set hasMore to false")

        mockRepository.searchResult = .success([])

        viewModel.query = "NonexistentBook"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertFalse(self.viewModel.hasMore)
            XCTAssertEqual(self.viewModel.page, 1) // Should not increment on empty result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetchNextPageError() {
        let expectation = XCTestExpectation(description: "Fetch error should be handled")

        let testError = NSError(domain: "TestError",
                                code: 123,
                                userInfo: [NSLocalizedDescriptionKey: "Test error message"]
        )
        mockRepository.searchResult = .failure(testError)

        viewModel.query = "ErrorQuery"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.viewModel.errorMessage, "Test error message")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetchNextPageDoesNotCallWhenLoading() {
        viewModel.isLoading = true
        viewModel.query = "Test"

        viewModel.fetchNextPage()

        XCTAssertEqual(mockRepository.searchCallCount, 0)
    }

    func testFetchNextPageDoesNotCallWhenNoMore() {
        viewModel.hasMore = false
        viewModel.query = "Test"

        viewModel.fetchNextPage()

        XCTAssertEqual(mockRepository.searchCallCount, 0)
    }

    // MARK: - Reset and Search Tests

    func testResetAndSearch() {
        // Set up initial state
        viewModel.page = 5
        viewModel.books = []
        viewModel.hasMore = false

        mockRepository.searchResult = .success([])

        viewModel.resetAndSearch()

        XCTAssertEqual(viewModel.page, 1)
        XCTAssertTrue(viewModel.books.isEmpty)
        XCTAssertTrue(viewModel.hasMore)
    }

    // MARK: - Refresh Tests

    func testRefresh() {
        // Set up initial state
        viewModel.page = 3
        viewModel.hasMore = false

        mockRepository.searchResult = .success([])

        viewModel.refresh()

        XCTAssertEqual(viewModel.page, 1)
        XCTAssertTrue(viewModel.hasMore)
    }

    // MARK: - Loading State Tests

    func testLoadingStateChanges() {
        let expectation = XCTestExpectation(description: "Loading state should change correctly")

        mockRepository.searchResult = .success([])

        // Monitor loading state changes
        var loadingStates: [Bool] = []
        viewModel.$isLoading
            .sink { loadingState in
                loadingStates.append(loadingState)
            }
            .store(in: &cancellables)

        viewModel.query = "Test"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            // Should have gone from false -> true -> false
            XCTAssertTrue(loadingStates.contains(true))
            XCTAssertFalse(self.viewModel.isLoading)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Error Message Tests

    func testErrorMessageClearedOnNewSearch() {
        let expectation = XCTestExpectation(description: "Error should be cleared on new search")

        // Mock search failure
        let testError = NSError(domain: "TestError",
                                code: 123,
                                userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )
        mockRepository.searchResult = .failure(testError)
        viewModel.query = "ErrorQuery"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertNotNil(self.viewModel.errorMessage)

            // Then mock a successful search
            self.mockRepository.searchResult = .success([])
            self.viewModel.query = "SuccessQuery"

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                XCTAssertNil(self.viewModel.errorMessage)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Pagination Tests

    func testPaginationIncrementsCorrectly() {
        let expectation = XCTestExpectation(description: "Page should increment after successful fetch")

        mockRepository.searchResult = .success([sampleBook])

        viewModel.query = "Test"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let initialPage = self.viewModel.page

            // Manually call fetchNextPage to simulate pagination
            self.viewModel.fetchNextPage()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertEqual(self.viewModel.page, initialPage + 1)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
