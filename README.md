# SwiftPagination

[![Swift Package CI](https://github.com/blejator90/SwiftPagination/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/blejator90/SwiftPagination/actions/workflows/ci-tests.yml)

![iOS](https://img.shields.io/badge/iOS-13+-green)
![macOS](https://img.shields.io/badge/macOS-10.15+-green)
![tvOS](https://img.shields.io/badge/tvOS-13+-green)
![watchOS](https://img.shields.io/badge/watchOS-6+-green)
![visionOS](https://img.shields.io/badge/visionOS-1+-green)

SwiftPagination is a simple and flexible Swift library for handling pagination with support for both numbered and keyset pagination. This library makes it easy to implement pagination in your iOS and macOS applications.

## Features

- Supports both numbered and keyset pagination.
- Simple and intuitive API.
- Asynchronous loading of pages.
- Handles state and error management.

## Installation

### Swift Package Manager

Add SwiftPagination to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/blejator90/swift-pagination.git", from: "0.1.0")
]
```

Then, add it as a dependency in your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        "SwiftPagination"
    ]
)
```

## Usage

### Numbered Pagination

Here's an example of how to use SwiftPagination with numbered pagination:

```swift
import SwiftPagination

struct MyItem: Decodable, Identifiable {
    let id: Int
    let name: String
}

let pagination = Pagination<MyItem>(
    pageSize: 10,
    initialPage: 1,
    fetchNumberedPage: { currentPage, pageSize in
        // Replace with your API call
        let items = (1...100).map { MyItem(id: $0, name: "Item \($0)") }
        let start = (currentPage - 1) * pageSize
        let end = min(start + pageSize, items.count)
        return Array(items[start..<end])
    }
)

// Load the first page
Task {
    do {
        let items = try await pagination.load()
        print("Loaded items: \(items)")
    } catch {
        print("Failed to load items: \(error)")
    }
}
```

### Keyset Pagination

Here's an example of how to use SwiftPagination with keyset pagination:

```swift
import SwiftPagination

struct MyItem: Decodable, Identifiable, PaginationKey {
    let id: Int
    let name: String
    let key: String
}

let pagination = Pagination<MyItem>(
    pageSize: 10,
    initialKey: nil,
    fetchKeysetPage: { lastKey, pageSize in
        // Replace with your API call
        let items = (1...100).map { MyItem(id: $0, name: "Item \($0)", key: "\($0)") }
        guard let lastKey = lastKey else {
            return Array(items.prefix(pageSize))
        }
        let startIndex = items.firstIndex { $0.key == lastKey } ?? 0
        let endIndex = min(startIndex + pageSize, items.count)
        return Array(items[startIndex..<endIndex])
    }
)

// Load the first page
Task {
    do {
        let items = try await pagination.load()
        print("Loaded items: \(items)")
    } catch {
        print("Failed to load items: \(error)")
    }
}
```

### Loading More Pages

To load more pages, simply call the `loadMore` method:

```swift
Task {
    do {
        let moreItems = try await pagination.loadMore()
        print("Loaded more items: \(moreItems)")
    } catch {
        print("Failed to load more items: \(error)")
    }
}
```

## Contributions and Ideas

Contributions and ideas are welcome! If you have suggestions for improvements or new features, please open an issue or submit a pull request. I appreciate your feedback and help in making SwiftPagination better.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
