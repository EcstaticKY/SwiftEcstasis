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
    
    func test_combinePublisherType() {
        let x = PassthroughSubject<String, Never>()
            .flatMap { name in
                return Future<String, Error> { promise in
                    promise(.success(""))
                    }.catch { _ in
                        Just("No user found")
                    }.map { result in
                        return "\(result) foo"
                }
        }
        
        print(type(of: x))
        
        print(type(of: x.eraseToAnyPublisher()))
    }
}
