///
/// Created by Zheng Kanyan on 2021/10/4.
/// 
///

import XCTest
import Foundation

class GCDTests: XCTestCase {

    func test_doNotKnowWhatToTest() {
        let queue = DispatchQueue(label: "myqueue")
//        let queue = DispatchQueue(label: "myqueue", qos: .default, attributes: .concurrent)
        
        queue.async {
            print(1)
        }
        
        queue.async {
            print(2)
        }
        
        queue.sync {
            print(3)
        }
        
        queue.sync {
            print(4)
        }
        
        print(0)
        
        queue.async {
            print(7)
        }
        
        queue.async {
            print(8)
        }
        
        queue.async {
            print(9)
        }
    }
    
    func test_deadLock() {
        // 用主队列的话，队列之间会锁住，造成死锁
        let queue = DispatchQueue(label: "serial queue")

        print("---start---\(Thread.current)");

        queue.sync {
            print("任务A-----\(Thread.current)");
        }
//
//        queue.sync {
//            print("任务B-----\(Thread.current)");
//        }
//
//        queue.sync {
//            print("任务C-----\(Thread.current)");
//        }

        print("---end-----\(Thread.current)");
    }
}
