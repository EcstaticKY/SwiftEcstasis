///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import XCTest
import BestPractice

protocol MessageImageDataStore {
    typealias Result = Swift.Result<Data, Error>
    func retrieve(with url: URL, completion: @escaping (Result) -> Void)
}

class LocalMessageImageDataLoader {
    private let store: MessageImageDataStore
    
    init(store: MessageImageDataStore) {
        self.store = store
    }
    
    enum Error: Swift.Error {
        case retrieval
        case notFound
    }
    func load(from url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void) {
        store.retrieve(with: url) { result in
            switch result {
            case .failure: completion(.failure(Error.retrieval))
            case .success: completion(.failure(Error.notFound))
            }
        }
    }
}

class LoadMessageImageDataFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotRequestImageData() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.loadURLs.isEmpty)
    }
    
    func test_load_requestsImageDataWithURL() {
        let url = anyURL()
        let (sut, store) = makeSUT()
        
        sut.load(from: url) { _ in }
        
        XCTAssertEqual(store.loadURLs, [url])
    }
    
    func test_loadTwice_requestsImageDataTwice() {
        let url = anyURL()
        let anotherURL = URL(string: "https://another-url.com")!
        let (sut, store) = makeSUT()
        
        sut.load(from: url) { _ in }
        sut.load(from: anotherURL) { _ in }
        
        XCTAssertEqual(store.loadURLs, [url, anotherURL])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(LocalMessageImageDataLoader.Error.retrieval)) {
            let error = anyNSError()
            store.completeWithError(error)
        }
    }
    
    func test_load_deliversNotFoundErrorOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(LocalMessageImageDataLoader.Error.notFound)) {
            let emptyData = Data()
            store.completeWithData(emptyData)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line)
        -> (sut: LocalMessageImageDataLoader, store: MessageImageDataStoreSpy) {
        
        let store = MessageImageDataStoreSpy()
        let sut = LocalMessageImageDataLoader(store: store)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalMessageImageDataLoader,
                        toCompleteWith expectedResult: MessageImageDataLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        sut.load(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, "Expected equal image data", file: file, line: line)
            case let (.failure(receivedError as LocalMessageImageDataLoader.Error), .failure(expectedError as LocalMessageImageDataLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, "Expected same error", file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class MessageImageDataStoreSpy: MessageImageDataStore {
        
        var loadURLs: [URL] {
            messages.map { $0.url }
        }
        private var messages = [(url: URL, completion: (MessageImageDataStore.Result) -> Void)]()
        
        func retrieve(with url: URL, completion: @escaping (MessageImageDataStore.Result) -> Void) {
            messages.append((url, completion))
        }
        
        func completeWithError(_ error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func completeWithData(_ data: Data, at index: Int = 0) {
            messages[index].completion(.success(data))
        }
    }
}
