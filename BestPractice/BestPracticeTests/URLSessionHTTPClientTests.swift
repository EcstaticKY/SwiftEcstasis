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
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_get_failsOnError() {
        let error = NSError(domain: "any error", code: 0)
        
        expect(resultFor: (data: nil, response: nil, error: error), equalTo: .failure(error))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    private func expect(resultFor stub: (data: Data?, response: URLResponse?, error: Error?),
                        equalTo expectedResult: HTTPClient.Result,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let receivedResult = resultFor(data: stub.data, response: stub.response, error: stub.error)
        
        switch (receivedResult, expectedResult) {
        case let (.success((receivedData, receivedResponse)), .success((expectedData, expectedResponse))):
            XCTAssertEqual(receivedData, expectedData, "Data not equal. expected \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            XCTAssertEqual(receivedResponse.statusCode, expectedResponse.statusCode, "Response status code not equal. expected \(expectedResult) got \(receivedResult) instead", file: file, line: line)
        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(receivedError.domain, expectedError.domain, "Error domain not equal. expected \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            XCTAssertEqual(receivedError.code, expectedError.code, "Error domain not equal. expected \(expectedResult) got \(receivedResult) instead", file: file, line: line)
        default:
            XCTFail("Expected \(expectedResult) got \(receivedResult) instead", file: file, line: line)
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClient.Result {
        
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        var receivedResults = [HTTPClient.Result]()
        let exp = expectation(description: "Wait for get completion")
        makeSUT().get(from: anyURL()) { result in
            receivedResults.append(result)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedResults.count, 1, "Expected one result, got \(receivedResults.count) results instead", file: file, line: line)
        
        return receivedResults[0]
    }
    
    private class URLProtocolStub: URLProtocol {
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
        }
        
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
