///
/// Created by Zheng Kanyan on 2021/9/17.
/// 
///

import XCTest

extension XCTestCase {
    func anyURL() -> URL { URL(string: "https://any-url.com")! }
    func anyData() -> Data { Data("any data".utf8) }
    func anyNSError() -> NSError { NSError(domain: "any error", code: 0) }
}
