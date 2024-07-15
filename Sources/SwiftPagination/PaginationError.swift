import Foundation

/// An enum representing possible errors encountered during pagination.
///
/// This enum defines various errors that can occur during pagination operations, including
/// already loading, reaching the end, and task cancellation.
public enum PaginationError: Error, LocalizedError {
    /// Indicates that a loading operation is already in progress.
    ///
    /// This error is thrown when a new loading operation is initiated while a previous
    /// loading operation is still ongoing.
    case alreadyLoading

    /// Indicates that there are no more items to load.
    ///
    /// This error is thrown when the end of the data set has been reached and no more
    /// items are available to load.
    case endReached

    /// Indicates that the loading operation was cancelled.
    ///
    /// This error is thrown when the current loading task is cancelled before it completes.
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .alreadyLoading:
            return "A loading operation is already in progress."
        case .endReached:
            return "No more items to load; the end has been reached."
        case .cancelled:
            return "The operation was cancelled."
        }
    }
}
