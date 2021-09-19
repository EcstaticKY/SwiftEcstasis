///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import XCTest
import BestPractice

class MessageImageDataLoaderWithFallbackComposite: MessageImageDataLoader {
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

    func test_load_deliversPrimayImageDataOnPrimarySuccess() {
        let primaryData = Data("primary".utf8)
        let fallbackData = Data("fallback".utf8)
        let (sut, _, _) = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))
        
        expect(sut, toCompleteWith: .success(primaryData))
    }
    
    func test_load_deliversFallbackImageDataOnPrimaryFailure() {
        let primaryError = anyNSError()
        let fallbackData = anyData()
        let (sut, _, _) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: .success(fallbackData))
        
        expect(sut, toCompleteWith: .success(fallbackData))
    }
    
    func test_load_failsOnPrimaryErrorWithFallbackError() {
        let primaryError = NSError(domain: "primary error", code: 0)
        let fallbackError = NSError(domain: "fallback error", code: 0)
        let (sut, _, _) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: .failure(fallbackError))
        
        expect(sut, toCompleteWith: .failure(fallbackError))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(primaryResult: MessageImageDataLoader.Result, fallbackResult: MessageImageDataLoader.Result, file: StaticString = #filePath, line: UInt = #line)
    -> (sut: MessageImageDataLoaderWithFallbackComposite, primary: MessageImageDataLoaderStub, fallback: MessageImageDataLoaderStub) {
        
        let primary = MessageImageDataLoaderStub(result: primaryResult)
        let fallback = MessageImageDataLoaderStub(result: fallbackResult)
        let sut = MessageImageDataLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        trackForMemoryLeak(primary, file: file, line: line)
        trackForMemoryLeak(fallback, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, primary, fallback)
    }
    
    private func expect(_ sut: MessageImageDataLoaderWithFallbackComposite,
                        toCompleteWith expectedResult: MessageImageDataLoader.Result,
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
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class MessageImageDataLoaderStub: MessageImageDataLoader {
        
        private let result: MessageImageDataLoader.Result
        
        init(result: MessageImageDataLoader.Result) {
            self.result = result
        }
        
        private class MessageImageDataLoadTaskSpy: MessageImageDataLoadTask {
            func cancel() { }
        }
        
        func load(from url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void) -> MessageImageDataLoadTask {
            
            completion(result)
            return MessageImageDataLoadTaskSpy()
        }
    }
}
