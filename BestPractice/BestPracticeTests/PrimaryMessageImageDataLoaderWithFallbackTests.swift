///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import XCTest
import BestPractice

class PrimaryMessageImageDataLoaderWithFallback: MessageImageDataLoader {
    private let primary: MessageImageDataLoader
    private let fallback: MessageImageDataLoader
    
    init(primary: MessageImageDataLoader, fallback: MessageImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    @discardableResult
    func load(from url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void) -> MessageImageDataLoadTask {
        
        primary.load(from: url) { [weak self] result in
            switch result {
            case let .success(data): completion(.success(data))
            case .failure:
                self?.fallback.load(from: url, completion: completion)
            }
        }
    }
}

class PrimaryMessageImageDataLoaderWithFallbackTests: XCTestCase {

    func test_load_deliversImageDataOnPrimarySuccess() {
        let (sut, primary, _) = makeSUT()
        let data = anyData()
        
        expect(sut, toCompleteWith: .success(data)) {
            primary.completeWithData(data)
        }
    }
    
    func test_load_deliversImageDataOnPrimaryErrorWithFallbackSuccess() {
        let (sut, primary, fallback) = makeSUT()
        let data = anyData()
        let error = anyNSError()
        
        expect(sut, toCompleteWith: .success(data)) {
            primary.completeWithError(error)
            fallback.completeWithData(data)
        }
    }
    
    func test_load_failsOnPrimaryErrorWithFallbackError() {
        let (sut, primary, fallback) = makeSUT()
        let error = anyNSError()
        let anotherError = NSError(domain: "another error", code: 0)
        
        expect(sut, toCompleteWith: .failure(anotherError)) {
            primary.completeWithError(error)
            fallback.completeWithError(anotherError)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line)
    -> (sut: PrimaryMessageImageDataLoaderWithFallback, primary: MessageImageDataLoaderSpy, fallback: MessageImageDataLoaderSpy) {
        
        let primary = MessageImageDataLoaderSpy()
        let fallback = MessageImageDataLoaderSpy()
        let sut = PrimaryMessageImageDataLoaderWithFallback(primary: primary, fallback: fallback)
        trackForMemoryLeak(primary, file: file, line: line)
        trackForMemoryLeak(fallback, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, primary, fallback)
    }
    
    private func expect(_ sut: PrimaryMessageImageDataLoaderWithFallback,
                        toCompleteWith expectedResult: MessageImageDataLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        sut.load(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, "Expected equal image data", file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, "Expected same error", file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class MessageImageDataLoaderSpy: MessageImageDataLoader {
        
        private var messages = [(url: URL, completion: (MessageImageDataLoader.Result) -> Void)]()
        
        private class MessageImageDataLoadTaskSpy: MessageImageDataLoadTask {
            func cancel() { }
        }
        
        func load(from url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void) -> MessageImageDataLoadTask {
            
            messages.append((url, completion))
            return MessageImageDataLoadTaskSpy()
        }
        
        func completeWithData(_ data: Data, at index: Int = 0) {
            messages[index].completion(.success(data))
        }
        
        func completeWithError(_ error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
    }
}
