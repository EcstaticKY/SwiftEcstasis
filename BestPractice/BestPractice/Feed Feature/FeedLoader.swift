///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import Foundation

public protocol FeedLoader {
    
    typealias Result = Swift.Result<[FeedImage], Error>
    func load(completion: @escaping (Result) -> Void)
}
