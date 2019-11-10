//
//  ViewController.swift
//  CombinePractice
//
//  Created by ParkHyunsoo on 2019/11/09.
//  Copyright © 2019 ParkHyunsoo. All rights reserved.
//

import UIKit
import Combine
import CoolLayout

class ViewController: UIViewController {
    
    private var cancellable: Cancellable!
    private var uibinding: Cancellable!
    
    private let filterField = UITextField {
        $0.placeholder = "place holder"
        $0.textColor = UIColor.black
        $0.textAlignment = .center
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setUpTextField()
//        subjectActions()
    }
}



extension ViewController {
    
    func setUpTextField() {
        
        self.view.addSubview(filterField)
        filterField.activate {
            $0.leadingAnchor == self.view.leadingAnchor + 20
            $0.trailingAnchor == self.view.trailingAnchor + -20
            $0.centerYAnchor == self.view.centerYAnchor + 0
        }
        
        // textfield 이벤트 publisher 형태로 방출(UIKit랑 combine이랑 안붙음? -> x)
        // ** uibinding이 구독이후 바로 메모리 해제되면서 cancel 되어서 그럼
        self.uibinding = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: filterField)
            .sink(receiveValue: { _ in })
        
        // pub를 구독하려는 subscriber는 output - input 타입이 같아야함 + failure 타입도
        // Publisher.Sequence(struct)은 Elements: Sequence, Output: Elements.Element 이라서 int가 아닌 [Int]
        let pub = Publishers.Sequence<[Int], Never>(sequence: [1, 2, 3, 4, 5])
            .delay(for: .milliseconds(1500), scheduler: DispatchQueue.main)
        // delay의 경우 다운스트림으로 모든 이벤트 방출 시점이 딜레이(구독 시점의 딜레이는 아닌듯..)
        
        // sink -> subscribe(...) / bind의 경우는 assign
        let subscribing = pub
            // This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
            .sink(receiveValue: { _ in })
        
        // 왜 바로 cancel 때렸는데 1.5초 이후 방출되는 이벤트가 sub에게 전달이 되는가.. sink 시점에 이미 초기 이벤트 방출 이벤트 + 타이밍을 다 캡처?
        subscribing.cancel()
        
        let pub2 = [0, 1, 2].publisher
        pub2
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    print("event stream2 finished")
                    break
                case .failure(let never):
//                    print(never)
                    break
                }
            }, receiveValue: { _ in
//                print("value2: \($0)")
            })
    }
    
    
    func subjectActions() {
        
        // 애는 왜 int야
        let pass = PassthroughSubject<Int, Never>()
        
        // Cancellable이 deinit 하는 순간에 call cancel
        // sink 이후 반환되는 AnyCancellable은 class 타입
        let cle = pass
            .sink(receiveValue: { _ in })
        
        (0...10).forEach { v in
            let delay = TimeInterval(v)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if v == 10 {
                    pass.send(completion: .finished)
                    return
                } else if v == 7 {
                    cle.cancel()
                }
                pass.send(v)
            }
            // 아마도 cancel 이후 cle 구독중지
            // 그리고 마지막 async 구문 이후 cle 메모리 해제
        }
        
        // ui binding의 경우 cancelBag이 필요함
    }
}
