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
    
    private class MessageImageDataLoadTaskWrapper: MessageImageDataLoadTask {
        var wrapped: MessageImageDataLoadTask?
        
        func cancel() {
            wrapped?.cancel()
        }
    }
    
    @discardableResult
    func load(from url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void) -> MessageImageDataLoadTask {
        
        let task = MessageImageDataLoadTaskWrapper()
        task.wrapped = primary.load(from: url) { [weak self] result in
            switch result {
            case .success: completion(result)
            case .failure:
                task.wrapped = self?.fallback.load(from: url, completion: completion)
            }
        }
        
        return task
    }
}

class PrimaryMessageImageDataLoaderWithFallbackTests: XCTestCase {

    func test_load_deliversPrimayImageDataOnPrimarySuccess() {
        let primaryData = Data("primary".utf8)
        let fallbackData = Data("fallback".utf8)
        let (sut, primary, fallback) = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))
        
        expect(sut, toCompleteWith: .success(primaryData)) {
            primary.complete()
            fallback.complete()
        }
    }
    
    func test_load_deliversFallbackImageDataOnPrimaryFailure() {
        let primaryError = anyNSError()
        let fallbackData = anyData()
        let (sut, primary, fallback) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: .success(fallbackData))
        
        expect(sut, toCompleteWith: .success(fallbackData)) {
            primary.complete()
            fallback.complete()
        }
    }
    
    func test_load_failsOnPrimaryErrorWithFallbackError() {
        let primaryError = NSError(domain: "primary error", code: 0)
        let fallbackError = NSError(domain: "fallback error", code: 0)
        let (sut, primary, fallback) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: .failure(fallbackError))
        
        expect(sut, toCompleteWith: .failure(fallbackError)) {
            primary.complete()
            fallback.complete()
        }
    }
    
    func test_cancelLoadTask_cancelsPrimaryLoadBeforePrimaryLoadingCompletion() {
        let primaryError = anyNSError()
        let fallbackData = anyData()
        let (sut, primary, fallback) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: .success(fallbackData))
        let url = anyURL()
        
        var receivedResults = [MessageImageDataLoader.Result]()
        (sut.load(from: url) { result in
            receivedResults.append(result)
        }).cancel()
        
        primary.complete()
        fallback.complete()
        
        XCTAssertEqual(primary.cancelledURLs, [url])
        XCTAssertTrue(fallback.cancelledURLs.isEmpty)
        XCTAssertTrue(receivedResults.isEmpty, "Expected no result after cancelling, got \(receivedResults) instead")
    }
    
    func test_cancelLoadTask_cancelsFallbackLoadAfterPrimaryLoadingCompletedWithError() {
        let primaryError = anyNSError()
        let fallbackData = anyData()
        let (sut, primary, fallback) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: .success(fallbackData))
        let url = anyURL()
        
        var receivedResults = [MessageImageDataLoader.Result]()
        let task = sut.load(from: url) { result in
            receivedResults.append(result)
        }
        
        primary.complete()
        
        task.cancel()
        fallback.complete()
        
        XCTAssertEqual(primary.cancelledURLs, [])
        XCTAssertEqual(fallback.cancelledURLs, [url])
        XCTAssertTrue(receivedResults.isEmpty, "Expected no result after cancelling, got \(receivedResults) instead")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(primaryResult: MessageImageDataLoader.Result = .success(Data()),
                         fallbackResult: MessageImageDataLoader.Result = .success(Data()),
                         file: StaticString = #filePath, line: UInt = #line)
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
    
    private class MessageImageDataLoaderStub: MessageImageDataLoader {
        
        private let result: MessageImageDataLoader.Result
        var cancelledURLs = [URL]()
        private var task: MessageImageDataLoadTaskSpy?
        
        init(result: MessageImageDataLoader.Result) {
            self.result = result
        }
        
        private class MessageImageDataLoadTaskSpy: MessageImageDataLoadTask {
            private let cancelCallback: (URL) -> Void
            private let url: URL
            private var completion: ((MessageImageDataLoader.Result) -> Void)?
            private var task: MessageImageDataLoadTaskSpy?
            
            init(url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void, callback: @escaping (URL) -> Void) {
                self.url = url
                self.cancelCallback = callback
                self.completion = completion
            }
            
            func cancel() {
                cancelCallback(url)
                preventFurtherComplete()
            }
            
            func complete(with result: MessageImageDataLoader.Result) {
                completion?(result)
            }
            
            private func preventFurtherComplete() {
                completion = nil
            }
        }
        
        func load(from url: URL, completion: @escaping (MessageImageDataLoader.Result) -> Void) -> MessageImageDataLoadTask {
            
            let task = MessageImageDataLoadTaskSpy(url: url, completion: completion) { [weak self] url in
                self?.cancelledURLs.append(url)
            }
            
            self.task = task
            
            return task
        }
        
        func complete() {
            task?.complete(with: result)
        }
    }
}
