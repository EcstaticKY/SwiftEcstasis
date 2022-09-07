///
/// Created by Zheng Kanyan on 2021/10/29.
/// 
///

#import <XCTest/XCTest.h>

typedef void (^Completion)(id item, NSError *error);

@protocol HTTPClient <NSObject>

- (void)getFromURL: (NSURL *)url completion: Completion;

@end

@protocol AnotherProtocol <NSObject>

- (void)haha;

@end

@interface RemoteHTTPClient : NSObject<HTTPClient, AnotherProtocol>

@property(nonatomic, strong) NSURLSession* session;

- (instancetype)initWithSession: (NSURLSession *)session;

@end

@implementation RemoteHTTPClient

- (instancetype)initWithSession: (NSURLSession *)session {
    self = [super init];
    self.session = session;
    return self;
}

- (void)getFromURL:(NSURL *)url completion:(id)Completion {
    
}

- (void)haha {
    NSLog(@"haha");
}

@end

@interface MyLoader: NSObject

@property(nonatomic, strong) id<HTTPClient, AnotherProtocol> something;

- (void)doSomething;
@end

@implementation MyLoader

- (instancetype)initWithSomething: (id<HTTPClient, AnotherProtocol>)something {
    self = [super init];
    self.something = something;
    return self;
}

- (void)doSomething {
    [self.something haha];
}

@end


@interface CleanOCTests : XCTestCase

@end

@implementation CleanOCTests

- (void)test_HTTPClient_init {
    NSURLSession *session = NSURLSession.sharedSession;
    id<HTTPClient, AnotherProtocol> client = [[RemoteHTTPClient alloc] initWithSession: session];
    MyLoader *loader = [[MyLoader alloc] initWithSomething: client];
    [loader doSomething];
}

@end
