//
//  ImageLoader.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 14/09/25.
//

import SwiftUI
import Combine

// Simple image loader with in-memory cache
class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    private static var cache = NSCache<NSString, UIImage>()
    private var cancellable: AnyCancellable?

    func load(from url: URL?) {
        guard let url = url else { return }

        // return cached image, if available
        if let cached = ImageLoader.cache.object(forKey: url.absoluteString as NSString) {
            self.image = cached
            return
        }

        // download and cache image
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ui in
                if let ui = ui {
                    ImageLoader.cache.setObject(ui, forKey: url.absoluteString as NSString)
                }
                self?.image = ui
            }
    }

    func cancel() {
        cancellable?.cancel()
    }
}
