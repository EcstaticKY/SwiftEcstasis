///
/// Created by Zheng Kanyan on 2021/10/28.
/// 
///

import XCTest
import BestPractice

class MultiplexingHTTPClientDecorator: HTTPClient {
    
    private let client: HTTPClient
    init(client: HTTPClient) {
        self.client = client
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        return client.get(from: url, completion: completion)
    }
    
}

class HhhTests: XCTestCase {

    func test_init_doesNotRequest() {
        let client = HTTPClientSpy()
        let _ = MultiplexingHTTPClientDecorator(client: client)
        XCTAssertTrue(client.messages.isEmpty)
    }
    
    private class HTTPClientSpy: HTTPClient {

        var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
        var requestURLs: [URL] {
            messages.map { $0.url }
        }
        var canceledURLs = [URL]()
        
        private struct HTTPClientTaskSpy: HTTPClientTask {
            let url: URL
            let callback: (URL) -> Void
            
            func cancel() {
                callback(url)
            }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            messages.append((url, completion))
            return HTTPClientTaskSpy(url: url) { [weak self] url in
                self?.canceledURLs.append(url)
            }
        }
        
        func completeWithError(at index: Int = 0) {
            messages[index].completion(.failure(NSError(domain: "any error", code: 0)))
        }
        
        func completeWith(_ data: Data, statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestURLs[index], statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
