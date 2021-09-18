///
/// Created by Zheng Kanyan on 2021/9/18.
/// 
///

import XCTest

class LocalMessageImageDataLoader {
    
}

class LoadMessageImageDataFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotRequestImageData() {
        let store = MessageImageDataStoreSpy()
        let _ = LocalMessageImageDataLoader()
        
        XCTAssert(store.loadURLs.isEmpty)
    }
    
    // MARK: - Helpers
    private class MessageImageDataStoreSpy {
        
        var loadURLs = [URL]()
    }
}
