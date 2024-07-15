/// A class that handles pagination for a generic type `T`.
///
/// This class supports both numbered and keyset pagination. It manages the state
/// and tasks for fetching paginated data, providing methods to load the first page
/// and subsequent pages.
///
/// - Note: Use the appropriate initializer for numbered or keyset pagination.
public class Pagination<T> {
    /// A type alias for the generic type `T`.
    ///
    /// This alias is used to refer to the items being paginated in a more readable manner.
    public typealias Item = T

    /// The number of items per page.
    public let pageSize: Int
    public private(set) var isLoading: Bool = false
    public private(set) var didReachEnd: Bool = false
    private var state: any PaginationState<T>
    private var currentTask: Task<[T], Error>?

    /// Initializes a `Pagination` instance for numbered pagination.
    ///
    /// - Parameters:
    ///   - pageSize: The number of items per page.
    ///   - initialPage: The initial page to start pagination from. Defaults to 1.
    ///   - fetchNumberedPage: A closure that fetches items given a page number and page size.
    public init(
        pageSize: Int,
        initialPage: Int = 1,
        fetchNumberedPage: @escaping (Int, Int) async throws -> [T]
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
        fetchKeysetPage: @escaping (String?, Int) async throws -> [T]
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
    /// - Throws:
    ///   - `PaginationError.cancelled` if the task is cancelled.
    ///   - `PaginationError` for other pagination-related errors.
    ///   - Any errors thrown by the fetch function.
    public func load() async throws -> [T] {
        currentTask?.cancel()
        currentTask = nil

        isLoading = true
        defer { isLoading = false }

        state = state.reset()
        didReachEnd = false

        let task = Task { [weak self] in
            guard let self = self else { throw PaginationError.cancelled }
            let items = try await self.state.fetch(pageSize: self.pageSize)
            if Task.isCancelled { throw PaginationError.cancelled }
            self.didReachEnd = items.count < self.pageSize
            self.state = self.state.update(items: items)
            return items
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
    /// - Throws:
    ///   - `PaginationError.alreadyLoading` if a loading operation is already in progress.
    ///   - `PaginationError.endReached` if there are no more items to load.
    ///   - `PaginationError.cancelled` if the task is cancelled.
    ///   - Any errors thrown by the fetch function.
    public func loadMore() async throws -> [T] {
        guard !isLoading else { throw PaginationError.alreadyLoading }
        guard !didReachEnd else { throw PaginationError.endReached }

        isLoading = true
        defer { isLoading = false }

        let task = Task { [weak self] in
            guard let self = self else { throw PaginationError.cancelled }
            let items = try await self.state.fetch(pageSize: self.pageSize)
            if Task.isCancelled { throw PaginationError.cancelled }
            self.didReachEnd = items.count < self.pageSize
            self.state = self.state.update(items: items)
            return items
        }
        currentTask = task
        return try await task.value
    }
}
