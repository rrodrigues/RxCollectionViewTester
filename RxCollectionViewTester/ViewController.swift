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

extension UIEdgeInsets {
    static func all(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
    }
    static func symmetric(vertical: CGFloat, horizontal: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

extension UIButton {
    class func withTitle(_ title: String) -> Self {
        let button = self.init(type: .system)
        button.setTitle(title, for: .normal)
        return button
    }
}

class ViewController: UIViewController {
    
    let bag = DisposeBag()
    
    let generateButton = UIButton.withTitle("Generate")
    let showAllButton = UIButton.withTitle("Show All")
    let removeAllButton = UIButton.withTitle("Remove All")
    
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

        showAllButton.isHidden = true
        removeAllButton.isHidden = true
        let stackButtons = UIStackView(arrangedSubviews: [
            generateButton,
            showAllButton,
            removeAllButton
            ])
        stackButtons.axis = .horizontal
        stackButtons.distribution = .fillEqually
        view.addSubview(stackButtons)
        
        collectionView.contentInset = UIEdgeInsets.all(20)
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: CollectionViewCell.identifier)
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        stackButtons.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(42)
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
        return CGSize(width: collectionView.frame.inset(by: collectionView.contentInset).width, height: 70)
    }
}

extension UIButton {
    class func image(_ image: UIImage, selected: UIImage? = nil) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.setImage(selected, for: .selected)
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
    let check = UIButton.image(#imageLiteral(resourceName: "unchecked"), selected: #imageLiteral(resourceName: "checked"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        ui()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func ui() {
        self.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.3).cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 2
        self.layoutMargins = UIEdgeInsets.symmetric(vertical: 8, horizontal: 12)
        
        let stackButtons = UIStackView(arrangedSubviews: [
            UIView(),
            plus,
            minus,
            check,
            delete
            ])
        stackButtons.axis = .horizontal
        stackButtons.alignment = .center
        stackButtons.distribution = .fill
        stackButtons.spacing = 8
        
        let stackView = UIStackView(arrangedSubviews: [
            label,
            stackButtons
            ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(self.snp.margins)
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
