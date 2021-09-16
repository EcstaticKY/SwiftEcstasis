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
    
    func load(from url: URL) {
        client.get(from: url) { _ in }
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
        
        sut.load(from: url)
        XCTAssertEqual(client.requestURLs, [url])
    }
    
    func test_loadTwice_requestImageDataTwice() {
        let url = anyURL()
        let (sut, client) = makeSUT()
        
        sut.load(from: url)
        sut.load(from: url)
        XCTAssertEqual(client.requestURLs, [url, url])
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
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            requestURLs.append(url)
        }
    }
    
    private func trackForMemoryLeak(_ obj: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak obj] in
            XCTAssertNil(obj, "Instance should be deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
