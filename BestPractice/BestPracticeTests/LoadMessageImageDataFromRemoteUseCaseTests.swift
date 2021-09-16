///
/// Created by Zheng Kanyan on 2021/9/16.
/// 
///

import XCTest
import BestPractice

final class RemoteMessageImageDataLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    typealias Result = Swift.Result<Data, Error>
    func load(from url: URL, completion: @escaping (Result) -> Void) {
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

class LoadMessageImageDataFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestImageData() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestURLs.isEmpty)
    }
    
    func test_load_requestsImageDataWithURL() {
        let url = anyURL()
        let (sut, client) = makeSUT()
        
        sut.load(from: url) { _ in }
        XCTAssertEqual(client.requestURLs, [url])
    }
    
    func test_loadTwice_requestsImageDataTwice() {
        let url = anyURL()
        let (sut, client) = makeSUT()
        
        sut.load(from: url) { _ in }
        sut.load(from: url) { _ in }
        XCTAssertEqual(client.requestURLs, [url, url])
    }
    
    func test_load_failsOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            client.completeWithError()
        }
    }
    
    func test_load_deliversInvalidDataOnNon200StatusCodeResponse() {
        let (sut, client) = makeSUT()
        let anyData = Data("any data".utf8)
        
        let samples = [199, 201, 250, 300, 404, 500]
        samples.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                client.completeWith(anyData, statusCode: statusCode, at: index)
            }
        }
    }
    
    func test_load_deliversInvalidDataOnEmptyDataWith200StatusCodeResponse() {
        let (sut, client) = makeSUT()
        let emptyData = Data()
        
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            client.completeWith(emptyData, statusCode: 200)
        }
    }
    
    func test_load_deliversDataOn200StatusCodeResponse() {
        let (sut, client) = makeSUT()
        let anyData = Data("any data".utf8)

        expect(sut, toCompleteWith: .success(anyData)) {
            client.completeWith(anyData, statusCode: 200)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteMessageImageDataLoader, client: HTTPClientSpy) {
        
        let client = HTTPClientSpy()
        let sut = RemoteMessageImageDataLoader(client: client)
        trackForMemoryLeak(client, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteMessageImageDataLoader,
                        toCompleteWith expectedResult: RemoteMessageImageDataLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        
        sut.load(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func anyURL() -> URL { URL(string: "https://any-url.com")! }
    
    private class HTTPClientSpy: HTTPClient {
        
        var requestURLs = [URL]()
        var completions = [(HTTPClient.Result) -> Void]()
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            requestURLs.append(url)
            completions.append(completion)
        }
        
        func completeWithError(at index: Int = 0) {
            completions[index](.failure(NSError(domain: "any error", code: 9)))
        }
        
        func completeWith(_ data: Data, statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestURLs[index], statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            completions[index](.success((data, response)))
        }
    }
    
    private func trackForMemoryLeak(_ obj: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak obj] in
            XCTAssertNil(obj, "Instance should be deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
