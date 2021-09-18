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
        
        let primary = MessageImageDataLoaderSpy()
        let fallback = MessageImageDataLoaderSpy()
        let sut = PrimaryMessageImageDataLoaderWithFallback(primary: primary, fallback: fallback)
        
        let exp = expectation(description: "Wait for load completion")
        sut.load(from: anyURL()) { result in
            switch result {
            case let .success(receivedData):
                XCTAssertEqual(receivedData, data)
            case .failure:
                XCTFail("Expected success data, got \(result) instead.")
            }
            exp.fulfill()
        }
        
        primary.completeWithData(data)
        
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
