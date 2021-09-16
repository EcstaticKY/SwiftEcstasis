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
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: RemoteMessageImageDataLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMessageImageDataLoader(client: client)
        return (sut, client)
    }
    
    private func anyURL() -> URL { URL(string: "https://any-url.com")! }
    
    private class HTTPClientSpy: HTTPClient {
        
        var requestURLs = [URL]()
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            requestURLs.append(url)
        }
    }
}
