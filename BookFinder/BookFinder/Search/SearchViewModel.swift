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
    @Published var books = [String]()
    @Published var isLoading: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {

    }

    // Pull to refresh
    func refresh() {

    }
}
