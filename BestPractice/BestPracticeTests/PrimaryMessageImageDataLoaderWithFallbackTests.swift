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
        
        primary.load(from: url) { result in
            if case .success = result {
                completion(result)
            }
        }
    }
}

class PrimaryMessageImageDataLoaderWithFallbackTests: XCTestCase {

    func test_load_deliversImageDataOnPrimarySuccess() {
        let data = anyData()
        let (sut, primary, _) = makeSUT()
        
        expect(sut, toCompleteWith: .success(data)) {
            primary.completeWithData(data)
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
    }
}
