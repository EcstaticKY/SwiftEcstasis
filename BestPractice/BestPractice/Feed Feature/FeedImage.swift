///
/// Created by Zheng Kanyan on 2021/9/20.
/// 
///

import Foundation

public struct FeedImage: Equatable {
    public init(uuid: UUID) {
        self.uuid = uuid
    }
    
    public let uuid: UUID
}
