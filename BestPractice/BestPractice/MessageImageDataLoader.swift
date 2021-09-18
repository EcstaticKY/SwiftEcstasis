///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import Foundation

public protocol MessageImageDataLoadTask {
    func cancel()
}

public protocol MessageImageDataLoader {
    
    typealias Result = Swift.Result<Data, Error>
    
    @discardableResult
    func load(from url: URL, completion: @escaping (Result) -> Void) -> MessageImageDataLoadTask
}
