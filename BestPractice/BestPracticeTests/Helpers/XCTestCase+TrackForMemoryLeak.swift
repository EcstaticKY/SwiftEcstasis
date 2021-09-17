///
/// Created by Zheng Kanyan on 2021/9/17.
/// 
///

import XCTest

extension XCTestCase {
    func trackForMemoryLeak(_ obj: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak obj] in
            XCTAssertNil(obj, "Instance should be deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
