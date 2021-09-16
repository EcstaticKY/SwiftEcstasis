///
/// Created by Zheng Kanyan on 2021/9/16.
/// 
///

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, URLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
