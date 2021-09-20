///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import Foundation

public struct LocalFeedImage: Equatable {
    public init(uuid: UUID) {
        self.uuid = uuid
    }
    
    public let uuid: UUID
}

public protocol FeedStore {
    
    func deleteCache(completion: @escaping (Error?) -> Void)
    
    func insert(_ localFeed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void)
    
    func retrieve(completion: @escaping (Result<(localFeed: [LocalFeedImage], timestamp: Date), Error>) -> Void)
}
