///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import Foundation

public protocol MessageImageDataRetrieveTask {
    func cancel()
}

public protocol MessageImageDataStore {
    typealias Result = Swift.Result<Data, Error>
    func retrieve(with url: URL, completion: @escaping (Result) -> Void) -> MessageImageDataRetrieveTask
}
