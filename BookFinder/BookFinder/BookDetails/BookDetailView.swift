//
//  BookDetailView.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 15/09/25.
//

import SwiftUI

struct BookDetailView: View {
    @StateObject private var viewModel: BookDetailViewModel

    @State private var rotationAngle: Double = 0

    init(book: Book) {
        _viewModel = StateObject(wrappedValue: BookDetailViewModel(book: book))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RemoteImage(imageURL: viewModel.book.coverURL)
                        .frame(width: 180, height: 260)
                        .cornerRadius(10)
                        .rotationEffect(.degrees(rotationAngle))
                        .onAppear {
                            // Start slow rotation animation
                            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        }
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.book.title)
                        .font(.title2)
                        .bold()
                    Text(viewModel.book.authorText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let year = viewModel.book.firstPublishYear {
                        Text("Published: \(year)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text(viewModel.book.description ?? "No description available.")
                            .font(.body)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Details")
        .onAppear {
            viewModel.loadDetailsIfNeeded()
        }
        .alert("Error", isPresented: Binding.constant(viewModel.errorMessage != nil)) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
    }
}

