//
//  Publishers.swift
//  CombinePracticeTests
//
//  Created by Sudo.park on 2019/11/10.
//  Copyright © 2019 ParkHyunsoo. All rights reserved.
//

import XCTest
import Combine

class CancellableBag {

    private var cancellables = [Cancellable]()
    
    func append(_ cancellable: Cancellable) {
        self.cancellables.append(cancellable)
    }
    
    deinit {
        self.cancellables.forEach {
            $0.cancel()
        }
        self.cancellables.removeAll()
    }
}

extension Cancellable {
    
    func disposed(by bag: CancellableBag) {
        bag.append(self)
    }
}

extension Result {
    
    static func from(sucess: Success) -> Self {
        return .success(sucess)
    }
    
    static func from(failure: Failure) -> Self {
        return .failure(failure)
    }
}

extension Result where Failure == Error {
    
    func asFuture() -> Future<Success, Failure> {
        return .init{ $0(self) }
    }
}


enum PublisherEvent<Output, Failure> {
    case next(_ value: Output)
    case error(_ error: Failure)
    case completed
    
    func prints(prefix: String) {
        switch self {
        case .next(let output):
            print("\(prefix) -> next: \(output)")
        case .completed:
            print("\(prefix) -> completed\n")
        case .error(let error):
            print("\(prefix) -> error: \(error)\n")
        }
    }
}

extension Publisher {
    
    func sink(on closure: @escaping (PublisherEvent<Output, Failure>) -> Void) -> Cancellable {
        self.sink(receiveCompletion: { complete in
            switch complete {
            case .finished:
                closure(.completed)
            case .failure(let error):
                closure(.error(error))
            }
        }, receiveValue: { output in
            closure(.next(output))
        })
    }
}

class PushisherTest: XCTestCase {
    
    private var bag: CancellableBag!
    
    override func setUp() {
        super.setUp()
        self.bag = CancellableBag()
    }
    
    override func tearDown() {
        super.tearDown()
        self.bag = nil
    }
}


extension PushisherTest {
    
    
    func test_just() {
        
        // == Observable.just, never fail
        Just(1)
            .sink(on: { event in
                event.prints(prefix: "Just")
            })
            .disposed(by: self.bag)
    }
    
    func test_future() {
        // result의 비동기 타입
        // promise closure에 result 전달
        Result.from(sucess: 1).asFuture()
            .sink(on: { event in
                event.prints(prefix: "Future")
            })
            .disposed(by: self.bag)
    }
    
    func test_empty() {
        
        // == completable
        let empty = Empty(completeImmediately: true, outputType: Int.self, failureType: Error.self)
        empty
            .sink(on: { event in
                event.prints(prefix: "Empty")
            })
            .disposed(by: self.bag)
        
        
    }
    
    func test_deferred() {
        // subscribe 이후에 publisher 생성?
        let deferred = Deferred
            { () -> AnyPublisher<Int, Never> in
                return Just(1)
                    .eraseToAnyPublisher()
            }
        
        deferred
            .createPublisher()
            .sink(on: { event in
                event.prints(prefix: "deferred")
            })
            .disposed(by: self.bag)
    }
    
    func test_fail() {
        
        // Failure == Error 방출 이후에 바로 종료
        struct DummyError {
            static func erase() -> Error {
                return NSError(domain: "", code: 0, userInfo: nil)
            }
        }
        let fail = Fail(outputType: Int.self, failure: DummyError.erase())
        fail
            .sink(on: { event in
                event.prints(prefix: "Fail")
            })
            .disposed(by: self.bag)
    }
    
    func test_record() {
        
        let record = Record<Int, Error>(output: [1, 2, 3, 4], completion: .finished)
        record
            .sink(on: { event in
                print("recording: \(record.recording)")
                event.prints(prefix: "Record")
            })
            .disposed(by: self.bag)
    }
}
