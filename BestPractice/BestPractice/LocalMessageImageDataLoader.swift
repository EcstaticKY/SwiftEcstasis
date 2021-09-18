///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import Foundation

public class LocalMessageImageDataLoader: MessageImageDataLoader {
    private let store: MessageImageDataStore
    
    public init(store: MessageImageDataStore) {
        self.store = store
    }
    
    private class MessageImageDataRetrieveTaskWrapper: MessageImageDataLoadTask {
        private var completion: ((MessageImageDataLoader.Result) -> Void)?
        var wrapped: MessageImageDataRetrieveTask?
        
        init(completion: @escaping (MessageImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func cancel() {
            preventFurtherComplete()
            wrapped?.cancel()
        }
        
        func complete(with result: MessageImageDataLoader.Result) {
            completion?(result)
            preventFurtherComplete()
        }
        
        private func preventFurtherComplete() {
            completion = nil
        }
    }
    
    public enum Error: Swift.Error {
        case retrieval
        case notFound
    }
    
    @discardableResult
    public func load(from url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void) -> MessageImageDataLoadTask {
        
        let task = MessageImageDataRetrieveTaskWrapper(completion: completion)
        
        task.wrapped = store.retrieve(with: url) { [weak self] result in
            guard self != nil else { return }
            
            task.complete(with: result.mapError { _ in Error.retrieval }.flatMap { data in
                return data.isEmpty ? .failure(Error.notFound) : .success(data)
            })
        }
        
        return task
    }
}
