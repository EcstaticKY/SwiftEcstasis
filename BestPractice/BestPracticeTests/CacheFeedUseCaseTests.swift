///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import XCTest
import BestPractice

class CacheFeedUseCaseTests: XCTestCase {

    func test_doesNotMessageStoreOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_save_doesNotRequestInsertingCacheOnDeletingError() {
        let (sut, store) = makeSUT()
        
        sut.save([uniqueItem(), uniqueItem()]) { _ in }
        XCTAssertEqual(store.messages, [.deleteCache])
        
        store.completeDeletionWith(anyNSError())
        XCTAssertEqual(store.messages, [.deleteCache])
    }
    
    func test_save_requestsInsertingCacheOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT { timestamp }
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.messages, [.deleteCache, .insert(items: items, timestamp: timestamp)])
    }
    
    func test_save_failsOnDeletingError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        
        expect(sut, toCompleteWithError: error) {
            store.completeDeletionWith(error)
        }
    }
    
    func test_save_failsOnInsertingError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        
        expect(sut, toCompleteWithError: error) {
            store.completeDeletionSuccessfully()
            store.completeInsertionWith(error)
        }
    }
    
    func test_save_succeedsOnSuccessfulInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverErrorAfterInstanceHasBeenDeallocatedWhenDeletingCache() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedErrors = [Error?]()
        sut?.save([uniqueItem(), uniqueItem()], completion: { error in
            receivedErrors.append(error)
        })
        
        sut = nil
        store.completeDeletionWith(anyNSError())
        store.completeDeletionSuccessfully()
        
        XCTAssertTrue(receivedErrors.isEmpty, "Expected no result dilivered. got \(receivedErrors) instead.")
    }
    
    func test_save_doesNotDeliverErrorAfterInstanceHasBeenDeallocatedWhenInsertingCache() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedErrors = [Error?]()
        sut?.save([uniqueItem(), uniqueItem()], completion: { error in
            receivedErrors.append(error)
        })
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertionWith(anyNSError())
        store.completeInsertionSuccessfully()
        
        XCTAssertTrue(receivedErrors.isEmpty, "Expected no result dilivered. got \(receivedErrors) instead.")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line)
        -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(uuid: UUID())
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWithError expectedError: Error?,
                        when action: () -> Void,
                        file: StaticString = #filePath, line: UInt = #line) {

        let items = [uniqueItem(), uniqueItem()]
        
        let exp = expectation(description: "Wait for load completion")
        sut.save(items) { error in
            XCTAssertEqual(error as NSError?, expectedError as NSError?)
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }
    
    private class FeedStoreSpy: FeedStore {
        
        enum Message: Equatable {
            case deleteCache
            case insert(items: [FeedItem], timestamp: Date)
        }
            
        var messages = [Message]()
        private var deleteCompletions = [(Error?) -> Void]()
        private var insertCompletions = [(Error?) -> Void]()
        
        func deleteCache(completion: @escaping (Error?) -> Void) {
            messages.append(.deleteCache)
            deleteCompletions.append(completion)
        }
        
        func completeDeletionWith(_ error: Error, at index: Int = 0) {
            deleteCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deleteCompletions[index](nil)
        }
        
        func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping (Error?) -> Void) {
            messages.append(.insert(items: items, timestamp: timestamp))
            insertCompletions.append(completion)
        }
        
        func completeInsertionWith(_ error: Error, at index: Int = 0) {
            insertCompletions[index](error)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertCompletions[index](nil)
        }
    }

}
