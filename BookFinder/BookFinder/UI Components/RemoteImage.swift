//
//  RemoteImage.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 14/09/25.
//

import SwiftUI
import Combine

/// Shows an image from given URL.
struct RemoteImage: View {
    @StateObject private var loader = ImageLoader()
    let imageURL: URL?
    var placeholder: some View {
        Rectangle()
            .foregroundColor(Color(.secondarySystemFill))
            .overlay(Text("No Image").font(.caption))
    }

    var body: some View {
        Group {
            if let img = loader.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .onAppear { loader.load(from: imageURL) }
        .onDisappear { loader.cancel() }
    }
}
