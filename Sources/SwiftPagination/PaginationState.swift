/// A protocol defining the state management for pagination.
///
/// This protocol provides the necessary methods to manage and update the state
/// of pagination, including resetting the state, fetching items, and updating the state
/// with new items.
public protocol PaginationState<Item> {
    /// The type of items being paginated.
    associatedtype Item

    /// Resets the pagination state to its initial state.
    ///
    /// - Returns: The initial state of the pagination.
    func reset() -> Self

    /// Fetches a page of items.
    ///
    /// - Parameter pageSize: The number of items per page.
    /// - Returns: An array of items of type `Item`.
    /// - Throws: Any errors encountered during the fetch operation.
    func fetch(pageSize: Int) async throws -> [Item]

    /// Updates the pagination state with new items.
    ///
    /// - Parameter items: The new items to update the state with.
    /// - Returns: The updated pagination state.
    func update(items: [Item]) -> Self
}
