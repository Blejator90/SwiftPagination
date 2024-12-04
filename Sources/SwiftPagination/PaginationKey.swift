/// A protocol representing a key for keyset pagination.
///
/// Types conforming to this protocol must provide a key that can be used for keyset pagination.
public protocol PaginationKey: Sendable {

    /// The key representing the current item's position in the dataset.
    ///
    /// This key is used to fetch the next set of items in keyset pagination.
    var key: String { get }
}
