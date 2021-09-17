///
/// Created by Zheng Kanyan on 2021/9/16.
/// 
///

import XCTest
import BestPractice

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
        
        let samples = [199, 201, 250, 300, 404, 500]
        samples.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                client.completeWith(anyData(), statusCode: statusCode, at: index)
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
        let data = anyData()

        expect(sut, toCompleteWith: .success(data)) {
            client.completeWith(data, statusCode: 200)
        }
    }
    
    func test_load_doesNotDeliverResultAfterInstanceHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteMessageImageDataLoader? = RemoteMessageImageDataLoader(client: client)
        
        var receivedResults = [RemoteMessageImageDataLoader.Result]()
        sut?.load(from: anyURL()) { result in
            receivedResults.append(result)
        }
        
        sut = nil
        client.completeWith(anyData(), statusCode: 200)
        
        XCTAssertTrue(receivedResults.isEmpty, "Expected no result, got \(receivedResults) instead")
    }
    
    func test_load_doesNotRequestsCancelling() {
        let (sut, client) = makeSUT()
        
        sut.load(from: anyURL()) { _ in }
        
        XCTAssertTrue(client.canceledURLs.isEmpty)
    }
    
    func test_load_cancelsTaskOnCancelling() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        
        let task = sut.load(from: url) { _ in }
        task.cancel()
        
        XCTAssertEqual(client.canceledURLs, [url])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line)
    -> (sut: RemoteMessageImageDataLoader, client: HTTPClientSpy) {
        
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
            return HTTPClientTaskSpy(url: url) { url in
                self.canceledURLs.append(url)
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
