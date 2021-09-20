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
    
    public enum LoadError: Swift.Error {
        case retrieval
        case notFound
    }
    
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        store.retrieve { [unowned self] result in
            switch result {
            case .failure: completion(.failure(LoadError.retrieval))
            case let .success((locals, timestamp)):
                guard !locals.isEmpty else { return completion(.failure(LoadError.notFound)) }
                
                let expiredDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: -7, to: self.currentDate())!
                
                if expiredDate >= timestamp {
                    completion(.failure(LoadError.notFound))
                } else {
                    completion(.success(locals.toModels()))
                }
            }
        }
    }
    
    public typealias SaveResult = Error?
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCache { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completion(error)
            } else {
                self.cache(feed, completion: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        let locals = feed.toLocal()
        self.store.insert(locals, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map { LocalFeedImage(uuid: $0.uuid) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        map { FeedImage(uuid: $0.uuid) }
    }
}
