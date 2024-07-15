/// A protocol representing a key for keyset pagination.
///
/// Types conforming to this protocol must provide a key that can be used for keyset pagination.
public protocol PaginationKey {
    var key: String { get }
}
