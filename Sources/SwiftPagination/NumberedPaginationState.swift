/// A struct representing the state for numbered pagination.
///
/// This struct manages the state for numbered pagination, including the current page number
/// and the function to fetch items based on the page number and page size.
public struct NumberedPaginationState<T>: PaginationState where T: Sendable {
    var currentPage: Int
    let fetchPage: @Sendable (Int, Int) async throws -> [T]

    public func reset() -> NumberedPaginationState<T> {
        return NumberedPaginationState(currentPage: 1, fetchPage: fetchPage)
    }

    public func fetch(pageSize: Int) async throws -> [T] {
        return try await fetchPage(currentPage, pageSize)
    }

    public func update(items: [T]) -> NumberedPaginationState<T> {
        return NumberedPaginationState(currentPage: currentPage + 1, fetchPage: fetchPage)
    }
}
