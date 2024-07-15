import XCTest
import ConcurrencyExtras
@testable import SwiftPagination

final class NumberedPaginationTests: XCTestCase {
    
    struct MyItem: Decodable, Identifiable {
        let id: Int
        let name: String
    }

    func testInitialLoad() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { currentPage, pageSize in
                await Task.yield()
                let items = (1...100).map { MyItem(id: $0, name: "Item \($0)") }
                let start = (currentPage - 1) * pageSize
                let end = min(start + pageSize, items.count)
                return Array(items[start..<end])
            }
        )

        XCTAssertFalse(pagination.isLoading)

        try await withMainSerialExecutor {
            let task = Task {
                let items = try await pagination.load()
                XCTAssertEqual(items.count, 10)
                XCTAssertEqual(items.first?.id, 1)
                XCTAssertEqual(items.last?.id, 10)
                XCTAssertFalse(pagination.isLoading)
            }

            await Task.yield()
            XCTAssertTrue(pagination.isLoading)
            try await task.value
        }
    }

    func testLoadMore() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { currentPage, pageSize in
                await Task.yield()
                let items = (1...100).map { MyItem(id: $0, name: "Item \($0)") }
                let start = (currentPage - 1) * pageSize
                let end = min(start + pageSize, items.count)
                return Array(items[start..<end])
            }
        )

        _ = try await pagination.load()
        XCTAssertFalse(pagination.isLoading)

        try await withMainSerialExecutor {
            let task = Task {
                let moreItems = try await pagination.loadMore()
                XCTAssertEqual(moreItems.count, 10)
                XCTAssertEqual(moreItems.first?.id, 11)
                XCTAssertEqual(moreItems.last?.id, 20)
                XCTAssertFalse(pagination.isLoading)
            }

            await Task.yield()
            XCTAssertTrue(pagination.isLoading)
            try await task.value
        }
    }

    func testInitialLoadCancelsPreviousRequest() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { currentPage, pageSize in
                await Task.yield()
                let items = (1...100).map { MyItem(id: $0, name: "Item \($0)") }
                let start = (currentPage - 1) * pageSize
                let end = min(start + pageSize, items.count)
                return Array(items[start..<end])
            }
        )

        await withMainSerialExecutor {
            let task1 = Task {
                do {
                    _ = try await pagination.load()
                    XCTFail("Expected to throw PaginationError.cancelled")
                } catch let error as PaginationError {
                    XCTAssertEqual(error, PaginationError.cancelled)
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }
            }

            await Task.yield()

            let task2 = Task {
                do {
                    let items = try await pagination.load()
                    XCTAssertEqual(items.count, 10)
                    XCTAssertEqual(items.first?.id, 1)
                    XCTAssertEqual(items.last?.id, 10)
                    XCTAssertFalse(pagination.isLoading)
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }
            }

            await Task.yield()

            await task2.value
            await task1.value
        }
    }

    func testAlreadyLoading() async {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { currentPage, pageSize in
                await Task.yield()
                let items = (1...100).map { MyItem(id: $0, name: "Item \($0)") }
                let start = (currentPage - 1) * pageSize
                let end = min(start + pageSize, items.count)
                return Array(items[start..<end])
            }
        )

        await withMainSerialExecutor {
            let task1 = Task {
                do {
                    _ = try await pagination.load()
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }
            }

            await Task.yield()
            XCTAssertTrue(pagination.isLoading)

            let task2 = Task {
                do {
                    _ = try await pagination.loadMore()
                    XCTFail("Expected to throw PaginationError.alreadyLoading")
                } catch let error as PaginationError {
                    XCTAssertEqual(error, PaginationError.alreadyLoading)
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }
            }

            await task1.value
            await task2.value
        }
    }

    func testReachedEnd() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { currentPage, pageSize in
                let items = (1...15).map { MyItem(id: $0, name: "Item \($0)") }
                let start = (currentPage - 1) * pageSize
                let end = min(start + pageSize, items.count)
                return Array(items[start..<end])
            }
        )

        _ = try await pagination.load()
        let moreItems = try await pagination.loadMore()
        XCTAssertEqual(moreItems.count, 5)

        do {
            _ = try await pagination.loadMore()
            XCTFail("Expected to throw PaginationError.endReached")
        } catch let error as PaginationError {
            XCTAssertEqual(error, PaginationError.endReached)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    func testZeroItems() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { _, _ in
                return []
            }
        )

        let items = try await pagination.load()
        XCTAssertTrue(items.isEmpty)
        XCTAssertTrue(pagination.didReachEnd)
    }

    func testExactPageSize() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { _, pageSize in
                let items = (1...pageSize).map { MyItem(id: $0, name: "Item \($0)") }
                return items
            }
        )

        let items = try await pagination.load()
        XCTAssertEqual(items.count, 10)
        XCTAssertEqual(items.first?.id, 1)
        XCTAssertEqual(items.last?.id, 10)
        XCTAssertFalse(pagination.didReachEnd)
    }

    func testOneLessThanPageSize() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { _, _ in
                let items = (1...9).map { MyItem(id: $0, name: "Item \($0)") }
                return items
            }
        )

        let items = try await pagination.load()
        XCTAssertEqual(items.count, 9)
        XCTAssertEqual(items.first?.id, 1)
        XCTAssertEqual(items.last?.id, 9)
        XCTAssertTrue(pagination.didReachEnd)
    }
    
    func testOneMoreThanPageSize() async throws {
        let pagination = Pagination<MyItem>(
            pageSize: 10,
            initialPage: 1,
            fetchNumberedPage: { currentPage, pageSize in
                let items = (1...11).map { MyItem(id: $0, name: "Item \($0)") }
                let start = (currentPage - 1) * pageSize
                let end = min(start + pageSize, items.count)
                return Array(items[start..<end])
            }
        )

        let items = try await pagination.load()
        XCTAssertEqual(items.count, 10)
        XCTAssertEqual(items.first?.id, 1)
        XCTAssertEqual(items.last?.id, 10)
        XCTAssertFalse(pagination.didReachEnd) // Still more items to load

        let moreItems = try await pagination.loadMore()
        XCTAssertEqual(moreItems.count, 1)
        XCTAssertEqual(moreItems.first?.id, 11)
        XCTAssertTrue(pagination.didReachEnd) // Now should reach the end
    }
}
