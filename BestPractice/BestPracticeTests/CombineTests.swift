///
/// Created by Zheng Kanyan on 2021/9/27.
/// 
///

import XCTest
import Combine

class CombineTests: XCTestCase {

    func test_simpleCombinePipeline() {
        let _ = Just(5).map { value in
            switch value {
            case _ where value < 1:
                return "none"
            case _ where value == 1:
                return "one"
            case _ where value == 2:
                return "couple"
            case _ where value == 3:
                return "few"
            case _ where value > 8:
                return "many"
            default:
                return "some"
            }
        }.sink { receivedValue in
            XCTAssertEqual(receivedValue, "some")
        }
    }
}
