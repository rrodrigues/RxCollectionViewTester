//
//  ViewController.swift
//  RxCollectionViewTester
//
//  Created by Rui Rodrigues on 03/01/2019.
//  Copyright © 2019 brownie. MIT License.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    let bag = DisposeBag()
    
    let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate", for: .normal)
        return button
    }()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    let value = PublishSubject<(id: UUID, value: Int)>()
    let delete = PublishSubject<UUID>()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(generateButton)
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: CollectionViewCell.identifier)
        collectionView.delegate = self
        view.addSubview(collectionView)

        generateButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(generateButton.snp.bottom)
            make.leading.bottom.trailing.equalToSuperview()
        }

        bind()
    }

    func bind() {
        // the two lines below are so we can avoid dealing with self in the closure.
        let value = self.value
        let delete = self.delete

        let input = Input(
            value: value,
            add: generateButton.rx.tap.asObservable(),
            delete: delete
        )
        let viewModel = ViewModel(input, initialValues: [])

        viewModel.counters
            .bind(to: collectionView.rx.items(cellIdentifier: CollectionViewCell.identifier, cellType: CollectionViewCell.self)) { index, element, cell in
                cell.configure(with: { input in
                    let vm = CellViewModel(input, initialValue: element.value)
                    // Remember the value property tracks the current value of the counter
                    vm.value
                        .map { (id: element.id, value: $0) } // tell the main view model which counter's value this is
                        .bind(to: value)
                        .disposed(by: cell.bag)

                    vm.delete
                        .map { element.id } // tell the main view model which counter should be deleted
                        .bind(to: delete)
                        .disposed(by: cell.bag)
                    return vm // hand the cell view model to the cell
                })
            }
            .disposed(by: bag)
    }
}


extension ViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.inset(by: collectionView.contentInset).width, height: 50)
    }
}

extension UIButton {
    class func image(_ image: UIImage) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        return button
    }
}

class CollectionViewCell: UICollectionViewCell {
    static var identifier: String { return "\(self)" }

    var bag = DisposeBag()

    let label = UILabel()
    let plus = UIButton.image(#imageLiteral(resourceName: "plus"))
    let minus = UIButton.image(#imageLiteral(resourceName: "minus"))
    let delete = UIButton.image(#imageLiteral(resourceName: "delete"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        ui()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func ui() {
        let stackView = UIStackView(arrangedSubviews: [
            label,
            plus,
            minus,
            delete
            ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with factory: @escaping (CellInput) -> CellViewModel) {
        // create the input object
        let input = CellInput(
            plus: plus.rx.tap.asObservable(),
            minus: minus.rx.tap.asObservable(),
            delete: delete.rx.tap.asObservable()
        )
        // create the view model from the factory
        let viewModel = factory(input)
        // bind the view model's label property to the label
        viewModel.label
            .bind(to: label.rx.text)
            .disposed(by: bag)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
}
