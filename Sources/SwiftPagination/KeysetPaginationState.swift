/// A struct representing the state for keyset pagination.
///
/// This struct manages the state for keyset pagination, including the last key used
/// and the function to fetch items based on a key and page size.
public struct KeysetPaginationState<T: PaginationKey>: PaginationState {
    var lastKey: String?
    let fetchPage: @Sendable (String?, Int) async throws -> [T]

    public func reset() -> KeysetPaginationState<T> {
        return KeysetPaginationState(lastKey: nil, fetchPage: fetchPage)
    }

    public func fetch(pageSize: Int) async throws -> [T] {
        return try await fetchPage(lastKey, pageSize)
    }

    public func update(items: [T]) -> KeysetPaginationState<T> {
        guard let lastItem = items.last else {
            return self
        }
        return KeysetPaginationState(lastKey: lastItem.key, fetchPage: fetchPage)
    }
}
