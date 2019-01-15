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
    let selectedChanged: Observable<(id: UUID, selected: Bool)>
	let add: Observable<Void>
	let delete: Observable<UUID>
}

struct ViewModel {
	let counters: Observable<[Model]>
}

extension ViewModel {
	private enum Action {
		case add
		case value(id: UUID, value: Int)
        case selectedChanged(id: UUID, selected: Bool)
		case delete(id: UUID)
	}

	init(_ input: Input, refreshTask: @escaping () -> [Model]) {
		let addAction = input.add.map { Action.add }
		let valueAction = input.value.map(Action.value)
        let selectedChangedAction = input.selectedChanged.map(Action.selectedChanged)
		let deleteAction = input.delete.map(Action.delete)
        
		counters = Observable.merge(addAction, valueAction, selectedChangedAction, deleteAction)
            .startWith(.add)
			.scan(into: []) { model, new in
				switch new {
				case .add:
                    model = refreshTask()
				case .value(let id, let value):
					if let index = model.index(where: { $0.id == id }) {
						model[index].value = value
					}
                case .selectedChanged(let id, let selected):
                    if let index = model.index(where: { $0.id == id }) {
                        model[index].selected = selected
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
    let select: Observable<Void>
    let delete: Observable<Void>
}

struct CellViewModel {
    let label: Observable<String>
    let selected: Observable<Bool>
    
    let selectedChanged: Observable<Bool>
    let value: Observable<Int>
    let delete: Observable<Void>
}

extension CellViewModel {
    init(_ input: CellInput, initialValue: Model) {
        let add = input.plus.map { 1 } // plus adds one to the value
        let subtract = input.minus.map { -1 } // minus subtracts one

        selectedChanged = input.select
            .scan(initialValue.selected, accumulator: { val, _ in !val })
        selected = selectedChanged
            .startWith(initialValue.selected)
        
        value = Observable.merge(add, subtract)
            .scan(initialValue.value, accumulator: +) // the logic is here

        label = Observable.combineLatest(value, selectedChanged)
            .startWith((initialValue.value, initialValue.selected))
            .map { "number is \($0) | selected \($1)" } // create the string from the value
        delete = input.delete // delete is just a passthrough in this case
    }
}
