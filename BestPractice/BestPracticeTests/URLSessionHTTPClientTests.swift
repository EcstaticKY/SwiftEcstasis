///
/// Created by Zheng Kanyan on 2021/9/17.
/// 
///

import XCTest
import BestPractice

class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    @discardableResult
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }
}

extension URLSessionTask: HTTPClientTask { }

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_get_failsOnError() {
        let sut = URLSessionHTTPClient()
        let error = NSError(domain: "any error", code: 0)
        
        URLProtocol.registerClass(URLProtocolStub.self)
        
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let exp = expectation(description: "Wait for get completion")
        sut.get(from: anyURL()) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got \(result) instead")
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }
    
    // MARK: - Helpers
    private func anyURL() -> URL { URL(string: "https://any-url.com")! }
    
    private class URLProtocolStub: URLProtocol {
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        private static var stub: Stub?
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() { }
    }
}
