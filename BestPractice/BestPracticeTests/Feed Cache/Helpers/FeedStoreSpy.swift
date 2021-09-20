///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import Foundation
import BestPractice

class FeedStoreSpy: FeedStore {
    
    enum Message: Equatable {
        case deleteCache
        case insert(models: [LocalFeedImage], timestamp: Date)
        case retrieval
    }
        
    var messages = [Message]()
    private var deleteCompletions = [(Error?) -> Void]()
    private var insertCompletions = [(Error?) -> Void]()
    private var retrieveCompletions = [(Result<(localFeed: [LocalFeedImage], timestamp: Date), Error>) -> Void]()
    
    func retrieve(completion: @escaping (Result<(localFeed: [LocalFeedImage], timestamp: Date), Error>) -> Void) {
        messages.append(.retrieval)
        retrieveCompletions.append(completion)
    }
    
    func deleteCache(completion: @escaping (Error?) -> Void) {
        messages.append(.deleteCache)
        deleteCompletions.append(completion)
    }
    
    func insert(_ localFeed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        messages.append(.insert(models: localFeed, timestamp: timestamp))
        insertCompletions.append(completion)
    }
    
    func completeDeletionWith(_ error: Error, at index: Int = 0) {
        deleteCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deleteCompletions[index](nil)
    }
    
    func completeInsertionWith(_ error: Error, at index: Int = 0) {
        insertCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertCompletions[index](nil)
    }
    
    func completeRetrievalWith(_ error: Error, at index: Int = 0) {
        retrieveCompletions[index](.failure(error))
    }
    
    func completeRetrievalWith(_ localFeed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrieveCompletions[index](.success((localFeed, timestamp)))
    }
}
