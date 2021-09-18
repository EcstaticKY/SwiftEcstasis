///
/// Created by Zheng Kanyan on 2021/9/16.
/// 
///

import Foundation

public final class RemoteMessageImageDataLoader: MessageImageDataLoader {
    private let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private class HTTPClientTaskWrapper: MessageImageDataLoadTask {
        var wrapped: HTTPClientTask?
        private var completion: ((Result) -> Void)?
        
        init(completion: @escaping (Result) -> Void) {
            self.completion = completion
        }
        
        func cancel() {
            preventFurtherCompletion()
            wrapped?.cancel()
        }
        
        func complete(with result: Result) {
            completion?(result)
            preventFurtherCompletion()
        }
        
        func preventFurtherCompletion() {
            completion = nil
        }
    }
    
    public typealias Result = MessageImageDataLoader.Result
    
    @discardableResult
    public func load(from url: URL, completion: @escaping (Result) -> Void) -> MessageImageDataLoadTask {
        
        let task = HTTPClientTaskWrapper(completion: completion)
        
        task.wrapped = client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            task.complete(with: result
                .mapError { _ in Error.connectivity }
                .flatMap { (data, response) in
                    let isValidResponse = !data.isEmpty && response.statusCode == 200
                    return isValidResponse ? .success(data) : .failure(Error.invalidData)
                })
        }
        
        return task
    }
}
