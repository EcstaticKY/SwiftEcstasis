///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import XCTest

protocol MessageImageDataStore {
    func retrieve(with url: URL)
}

class LocalMessageImageDataLoader {
    private let store: MessageImageDataStore
    
    init(store: MessageImageDataStore) {
        self.store = store
    }
    
    func load(from url: URL) {
        store.retrieve(with: url)
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
        
        sut.load(from: url)
        
        XCTAssertEqual(store.loadURLs, [url])
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
    
    private class MessageImageDataStoreSpy: MessageImageDataStore {
        
        var loadURLs = [URL]()
        
        func retrieve(with url: URL) {
            loadURLs.append(url)
        }
    }
}
