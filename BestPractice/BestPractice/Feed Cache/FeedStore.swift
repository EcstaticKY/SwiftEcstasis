///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import Foundation

public protocol FeedStore {
    func deleteCache(completion: @escaping (Error?) -> Void)
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping (Error?) -> Void)
}
