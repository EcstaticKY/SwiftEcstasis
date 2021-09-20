///
/// Created by Zheng Kanyan on 2021/9/20.
///
///

import XCTest
import BestPractice

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotRequestLoad() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.messages, [])
    }

    func test_load_requestsLoadingFeed() {
        let (sut, store) = makeSUT()

        sut.load() { _ in }

        XCTAssertEqual(store.messages, [.retrieval])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: failure(.retrieval)) {
            let error = anyNSError()
            store.completeRetrievalWith(error)
        }
    }

    func test_load_deliversNotFoundErrorOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: failure(.notFound)) {
            let emptyLocalFeed: [LocalFeedImage] = []
            store.completeRetrievalWith(emptyLocalFeed, timestamp: Date())
        }
    }

    func test_load_deliversNotFoundErrorOnMoreThanSeveDaysCache() {
        let now = Date()
        let moreThanSevenDaysPlusOneSecondTimeBefore = now.adding(-7, type: .day).adding(-1, type: .second)
        
        let (sut, store) = makeSUT { now }

        expect(sut, toCompleteWith: failure(.notFound)) {
            let feed = uniqueFeed()
            store.completeRetrievalWith(feed.locals, timestamp: moreThanSevenDaysPlusOneSecondTimeBefore)
        }
    }
    
    func test_load_deliversFeedOnNonExpiredCache() {
        let now = Date()
        let moreThanSevenDaysMinusOneSecondTimeBefore = now.adding(-7, type: .day).adding(1, type: .second)
        
        let (sut, store) = makeSUT { now }
        let feed = uniqueFeed()

        expect(sut, toCompleteWith: .success(feed.models)) {
            
            store.completeRetrievalWith(feed.locals, timestamp: moreThanSevenDaysMinusOneSecondTimeBefore)
        }
    }
//
//    func test_load_deliversCachedFeedOnNonExpiredCache() {
//        let (sut, store) = makeSUT()
//        let feed = uniqueFeed()
//        let data = anyData()
//
//        expect(sut, toCompleteWith: .success(feed.models)) {
//            store.completeWithFeed(feed.locals)
//        }
//    }
//
//    func test_load_doesNotDeliverResultAfterInstanceHasBeenDeallocated() {
//        let store = FeedStoreSpy()
//        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)
//
//        var receivedResults = [LocalFeedLoader.Result]()
//        sut?.load { result in
//            receivedResults.append(result)
//        }
//
//        sut = nil
//        store.completeWithFeed(uniqueFeed.locals)
//        store.completeWithError(anyNSError())
//
//        XCTAssertTrue(receivedResults.isEmpty, "Expected no result, got \(receivedResults) instead")
//    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line)
        -> (sut: LocalFeedLoader, store: FeedStoreSpy) {

        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWith expectedResult: FeedLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #filePath, line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedfeed)):
                XCTAssertEqual(receivedFeed, expectedfeed, "Expected equal feed", file: file, line: line)
            case let (.failure(receivedError as LocalFeedLoader.LoadError), .failure(expectedError as LocalFeedLoader.LoadError)):
                XCTAssertEqual(receivedError, expectedError, "Expected same error", file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }

    private func failure(_ error: LocalFeedLoader.LoadError) -> FeedLoader.Result {
        .failure(error)
    }
    
    private func uniqueFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        func uniqueItem() -> FeedImage {
            FeedImage(uuid: UUID())
        }
        
        let models = [uniqueItem(), uniqueItem()]
        let locals = models.map { LocalFeedImage(uuid: $0.uuid) }
        
        return (models, locals)
    }
}

extension Date {
    func adding(_ num: Int, type component: Calendar.Component) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: component, value: num, to: self)!
    }
}
