//
//  SearchView.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 13/09/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search books by title...", text: $vm.query)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 8)
                    if vm.isLoading {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                }
                .padding()

                if let err = vm.errorMessage {
                    Text("Error: \(err)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // List with infinite scrolling and pull-to-refresh
                List {
                    ForEach(vm.books) { book in
                        BookRowView(book: book)
                            .onAppear {
                            }
                    }
                    if vm.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable { // iOS15+ built-in; for iOS14 you'd implement UIRefreshControl bridging
                    vm.refresh()
                }
            }
            .navigationTitle("Book Finder")
        }
    }
}

