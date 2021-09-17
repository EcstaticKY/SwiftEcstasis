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
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    @discardableResult
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                return completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                return completion(.success((data, response)))
            }
            completion(.failure(UnexpectedValuesRepresentation()))
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
    
    func test_getFromURL_performGETRequestWithURL() {
        let sut = makeSUT()
        let url = anyURL()
        
        let exp = expectation(description: "Wait for completion")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        sut.get(from: url) { _ in }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnOnlyRequestError() {
        let error = anyNSError()
        let receivedError = resultErrorFor((data: nil, response: nil, error: error)) as NSError?
        XCTAssertEqual(error.domain, receivedError?.domain)
        XCTAssertEqual(error.code, receivedError?.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        
        XCTAssertNotNil(resultErrorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: anyNonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: nil)))
        
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: anyNonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: anyNonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: anyHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: anyNSError())))
        
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: anyNonHTTPURLResponse(), error: anyNSError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())))
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        
        let value = resultValuesFor((data: nil, response: response, error: nil))
        
        let emptyData = Data()
        XCTAssertEqual(value?.data, emptyData)
        XCTAssertEqual(value?.response.statusCode, response.statusCode)
        XCTAssertEqual(value?.response.url, response.url)
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let response = anyHTTPURLResponse()
        let data = anyData()
        
        let value = resultValuesFor((data: data, response: response, error: nil))
        
        XCTAssertEqual(value?.data, data)
        XCTAssertEqual(value?.response.statusCode, response.statusCode)
        XCTAssertEqual(value?.response.url, response.url)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let error = resultErrorFor { $0.cancel() } as NSError?
        
        XCTAssertEqual(error?.code, URLError.cancelled.rawValue)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    private func resultValuesFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?),
        file: StaticString = #filePath,
        line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        
        let result = resultFor(values, file: file, line: line)
        switch result {
        case .failure:
            XCTFail("Expected success, got \(result) inseted", file: file, line: line)
            return nil
        case let .success((data, response)):
            if let response = response as HTTPURLResponse? {
                return (data, response)
            } else {
                XCTFail("Expected success with HTTPURLResponse, got \(result) inseted", file: file, line: line)
                return nil
            }
        }
    }
    
    private func resultErrorFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?) = (nil, nil, nil),
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #filePath, line: UInt = #line) -> Error? {
        
        let result = resultFor(values, taskHandler: taskHandler, file: file, line: line)
        switch result {
        case let .failure(error):
            return error
        case .success:
            XCTFail("Expected error, got \(result) inseted", file: file, line: line)
            return nil
        }
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func anyNonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func resultFor(
        _ values: (data: Data?, response: URLResponse?, error: Error?),
        taskHandler: (HTTPClientTask) -> Void = { _ in },
        file: StaticString = #filePath, line: UInt = #line) -> HTTPClient.Result {
        
        URLProtocolStub.stub(data: values.data, response: values.response, error: values.error)
        
        let exp = expectation(description: "Wait for get completion")
        var receivedResult: HTTPClient.Result!
        taskHandler(makeSUT().get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        })
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private class URLProtocolStub: URLProtocol {
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        private static var stub: Stub?
        private static var observer: ((URLRequest) -> Void)?
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequest(_ observer: @escaping (URLRequest) -> Void) {
            self.observer = observer
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            observer = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            observer?(request)
            return true
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
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}
