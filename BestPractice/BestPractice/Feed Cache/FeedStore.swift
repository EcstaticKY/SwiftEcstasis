///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import Foundation

public struct LocalFeedItem: Equatable {
    public init(uuid: UUID) {
        self.uuid = uuid
    }
    
    public let uuid: UUID
}

public protocol FeedStore {
    func deleteCache(completion: @escaping (Error?) -> Void)
    func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping (Error?) -> Void)
}
