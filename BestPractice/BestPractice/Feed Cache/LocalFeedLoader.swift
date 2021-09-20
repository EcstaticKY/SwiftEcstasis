///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public typealias SaveResult = Error?
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCache { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(error)
            } else {
                self.cache(items, completion: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        let localItems = items.toLocal()
        self.store.insert(localItems, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        map { $0.toLocal() }
    }
}

private extension FeedItem {
    func toLocal() -> LocalFeedItem {
        LocalFeedItem(uuid: uuid)
    }
}
