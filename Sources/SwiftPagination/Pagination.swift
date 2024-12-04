/// A class that handles pagination for a generic type `T`.
///
/// This class supports both numbered and keyset pagination. It manages the state
/// and tasks for fetching paginated data, providing methods to load the first page
/// and subsequent pages.
///
/// - Note: Use the appropriate initializer for numbered or keyset pagination.
///
/// ### Example Usage
///
/// ```swift
/// // Define a model for the paginated items
/// struct Item: Sendable, PaginationKey {
///     let id: UUID
///     let name: String
///
///     // Provide the pagination key
///     var paginationKey: String { id.uuidString }
/// }
///
/// // Initialize the Pagination instance for keyset pagination
/// let pagination = Pagination<Item>(
///     pageSize: 10,
///     initialKey: nil,
///     fetchKeysetPage: { key, pageSize in
///         // Assumes 'repository' is a service handling data fetching
///         try await repository.fetch(from: key, pageSize: pageSize)
///     }
/// )
///
/// // Load paginated data
/// Task {
///     do {
///         // Fetch the first page
///         let firstPage = try await pagination.load()
///         print("Loaded first page with \(firstPage.count) items.")
///
///         // Fetch additional pages until all data is loaded
///         while !pagination.didReachEnd {
///             let nextPage = try await pagination.loadMore()
///             print("Loaded next page with \(nextPage.count) items.")
///         }
///
///         print("All pages loaded.")
///     } catch {
///         print("Error: \(error)")
///     }
/// }
/// ```
///
/// This example demonstrates how to:
/// - Use `load` to fetch the first page with a keyset-based approach.
/// - Use `loadMore` to fetch subsequent pages until no more data is available.
/// - Handle errors gracefully during fetching.

@MainActor
public final class Pagination<T> where T: Sendable {
    /// A type alias for the generic type `T`.
    ///
    /// This alias is used to refer to the items being paginated in a more readable manner.
    public typealias Item = T

    /// The number of items per page.
    public let pageSize: Int

    /// A flag indicating whether a pagination operation is currently in progress.
    ///
    /// This property is `true` while data is being fetched and `false` otherwise.
    public private(set) var isLoading: Bool = false

    /// A flag indicating whether all pages have been loaded.
    ///
    /// This property is `true` if no more items are available to load, and `false` otherwise.
    public private(set) var didReachEnd: Bool = false

    private var state: any PaginationState<T>
    private var currentTask: Task<[T], any Error>?

    /// Initializes a `Pagination` instance for numbered pagination.
    ///
    /// - Parameters:
    ///   - pageSize: The number of items per page.
    ///   - initialPage: The initial page to start pagination from. Defaults to 1.
    ///   - fetchNumberedPage: A closure that fetches items given a page number and page size.
    public init(
        pageSize: Int,
        initialPage: Int = 1,
        fetchNumberedPage: @Sendable @escaping (Int, Int) async throws -> [T]
    ) {
        self.pageSize = pageSize
        self.state = NumberedPaginationState(currentPage: initialPage, fetchPage: fetchNumberedPage)
    }

    /// Initializes a `Pagination` instance for keyset pagination.
    ///
    /// - Parameters:
    ///   - pageSize: The number of items per page.
    ///   - initialKey: The initial key to start pagination from. Defaults to `nil`.
    ///   - fetchKeysetPage: A closure that fetches items given a key and page size.
    public init(
        pageSize: Int,
        initialKey: String? = nil,
        fetchKeysetPage: @Sendable @escaping (String?, Int) async throws -> [T]
    ) where T: PaginationKey {
        self.pageSize = pageSize
        self.state = KeysetPaginationState(lastKey: initialKey, fetchPage: fetchKeysetPage)
    }

    /// Loads the first page of items, resetting any previous state.
    ///
    /// This method cancels any ongoing pagination tasks and resets the pagination state.
    /// It fetches the first page of items using the provided fetch function.
    ///
    /// - Returns: An array of items of type `T`.
    /// - Throws: ``PaginationError``
    ///
    /// ### Errors
    /// The following errors may occur during pagination:
    /// - ``PaginationError/alreadyLoading``: A loading operation is already in progress.
    /// - ``PaginationError/endReached``: No more items are available to load.
    /// - ``PaginationError/cancelled``: The task was cancelled.
    /// - Any errors thrown by the fetch function.
    public func load() async throws -> [T] {
        resetState()

        isLoading = true
        defer { isLoading = false }

        let task = Task { [weak self] in
            guard let self = self else { throw PaginationError.cancelled }
            return try await perform(state: state)
        }
        currentTask = task
        return try await task.value
    }

    /// Loads the next page of items.
    ///
    /// This method fetches the next page of items using the provided fetch function. It manages
    /// the pagination state and updates the state accordingly.
    ///
    /// - Returns: An array of items of type `T`.
    /// - Throws: ``PaginationError``
    ///
    /// ### Errors
    /// The following errors may occur during pagination:
    /// - ``PaginationError/alreadyLoading``: A loading operation is already in progress.
    /// - ``PaginationError/endReached``: No more items are available to load.
    /// - ``PaginationError/cancelled``: The task was cancelled.
    /// - Any errors thrown by the fetch function.
    public func loadMore() async throws -> [T] {
        guard !isLoading else { throw PaginationError.alreadyLoading }
        guard !didReachEnd else { throw PaginationError.endReached }

        isLoading = true
        defer { isLoading = false }

        let task = Task { [weak self, state = state] in
            guard let self = self else { throw PaginationError.cancelled }
            return try await perform(state: state)
        }
        currentTask = task
        return try await task.value
    }

    private func resetState() {
        currentTask?.cancel()
        currentTask = nil
        state = state.reset()
        didReachEnd = false
    }

    private func perform(state: some PaginationState<T>) async throws -> [T] {
        let items = try await self.state.fetch(pageSize: self.pageSize)
        if Task.isCancelled { throw PaginationError.cancelled }
        self.didReachEnd = items.count < self.pageSize
        self.state = self.state.update(items: items)
        return items
    }
}
