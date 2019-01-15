//
//  Repository.swift
//  RxCollectionViewTester
//
//  Created by Rui Rodrigues on 15/01/2019.
//  Copyright © 2019 brownie. All rights reserved.
//

import Foundation

struct Model {
    let id = UUID()
    var value: Int
    var selected: Bool = Bool.random()
    
    init(_ v: Int) {
        self.value = v
    }
}

class Repository {

    func refreshValues() -> [Model] {
        return (0..<20)
            .map { _ in Int.random(in: 0..<100) }
            .map { Model($0) }
    }
    
}
