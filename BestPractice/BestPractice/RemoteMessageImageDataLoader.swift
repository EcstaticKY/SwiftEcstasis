///
/// Created by Zheng Kanyan on 2021/9/16.
/// 
///

import Foundation

public final class RemoteMessageImageDataLoader {
    private let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = Swift.Result<Data, Error>
    public func load(from url: URL, completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                guard data.count > 0 && response.statusCode == 200 else {
                    return completion(.failure(.invalidData))
                }
                completion(.success(data))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
