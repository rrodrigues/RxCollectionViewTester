//
//  Repository.swift
//  RxCollectionViewTester
//
//  Created by Rui Rodrigues on 15/01/2019.
//  Copyright © 2019 brownie. All rights reserved.
//

import Foundation
import RxSwift

struct Model {
    let id = UUID()
    var value: Int
    var selected: Bool = Bool.random()
    
    init(_ v: Int) {
        self.value = v
    }
}

class Repository {
    
    let scheduler = SerialDispatchQueueScheduler(qos: .background)

    func refreshValues() -> Observable<[Model]> {
        let scheduler = self.scheduler
        return Observable.deferred {
            let models = (0..<20)
                .map { _ in Int.random(in: 0..<100) }
                .map { Model($0) }
            return .just(models, scheduler: scheduler)
        }
    }
    
}
