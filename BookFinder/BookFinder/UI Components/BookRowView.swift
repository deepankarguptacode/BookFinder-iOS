//
//  BookRowView.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 14/09/25.
//

import SwiftUI

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImage(imageURL: book.coverURL)
                .frame(width: 60, height: 90)
                .cornerRadius(6)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.authorText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let year = book.firstPublishYear {
                    Text("First published: \(year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
