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
        let client = HTTPClientSpy()
        let _ = RemoteMessageImageDataLoader(client: client)
        XCTAssertTrue(client.requestURLs.isEmpty)
    }
    
    func test_load_requestsImageDataWithURL() {
        let url = anyURL()
        let client = HTTPClientSpy()
        let sut = RemoteMessageImageDataLoader(client: client)
        sut.load(from: url)
        XCTAssertEqual(client.requestURLs, [url])
    }
    
    // MARK: - Helpers
    
    private func anyURL() -> URL { URL(string: "https://any-url.com")! }
    
    private class HTTPClientSpy: HTTPClient {
        
        var requestURLs = [URL]()
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            requestURLs.append(url)
        }
    }
}
