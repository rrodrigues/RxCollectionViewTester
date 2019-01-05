//
//  ViewModel.swift
//  RxCollectionViewTester
//
//  Created by Daniel Tartaglia on 1/5/19.
//  Copyright © 2019 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

struct Input {
	let value: Observable<(id: UUID, value: Int)>
	let add: Observable<Void>
	let delete: Observable<UUID>
}

struct ViewModel {
	let counters: Observable<[(id: UUID, value: Int)]>
}

extension ViewModel {
	private enum Action {
		case add
		case value(id: UUID, value: Int)
		case delete(id: UUID)
	}

	init(_ input: Input, initialValues: [(id: UUID, value: Int)]) {
		let addAction = input.add.map { Action.add }
		let valueAction = input.value.map(Action.value)
		let deleteAction = input.delete.map(Action.delete)
		counters = Observable.merge(addAction, valueAction, deleteAction)
            .startWith(.add)
			.scan(into: initialValues) { model, new in
				switch new {
				case .add:
                    model = (0..<20)
                        .map { _ in Int.random(in: 0..<100) }
                        .map { (UUID(), $0) }
				case .value(let id, let value):
					if let index = model.index(where: { $0.id == id }) {
						model[index].value = value
					}
				case .delete(let id):
					if let index = model.index(where: { $0.id == id }) {
						model.remove(at: index)
					}
				}
		}
	}
}

struct CellInput {
    let plus: Observable<Void>
    let minus: Observable<Void>
    let delete: Observable<Void>
}

struct CellViewModel {
    let label: Observable<String>
    let value: Observable<Int>
    let delete: Observable<Void>
}

extension CellViewModel {
    init(_ input: CellInput, initialValue: Int) {
        let add = input.plus.map { 1 } // plus adds one to the value
        let subtract = input.minus.map { -1 } // minus subtracts one

        value = Observable.merge(add, subtract)
            .scan(initialValue, accumulator: +) // the logic is here

        label = value
            .startWith(initialValue)
            .map { "number is \($0)" } // create the string from the value
        delete = input.delete // delete is just a passthrough in this case
    }
}
