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
    }
    
    func load(from url: URL, completion: @escaping (Error) -> Void) {
        client.get(from: url) { _ in
            completion(.connectivity)
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

        let exp = expectation(description: "Wait for load completion")
        
        var receivedErrors = [RemoteMessageImageDataLoader.Error]()
        sut.load(from: anyURL()) { error in
            receivedErrors.append(error)
            exp.fulfill()
        }
        client.completeWithError()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedErrors, [.connectivity])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteMessageImageDataLoader, client: HTTPClientSpy) {
        
        let client = HTTPClientSpy()
        let sut = RemoteMessageImageDataLoader(client: client)
        trackForMemoryLeak(client, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, client)
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
    }
    
    private func trackForMemoryLeak(_ obj: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak obj] in
            XCTAssertNil(obj, "Instance should be deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
