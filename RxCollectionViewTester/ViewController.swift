//
//  ViewController.swift
//  RxCollectionViewTester
//
//  Created by Rui Rodrigues on 03/01/2019.
//  Copyright © 2019 brownie. All rights reserved.
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
    
    let items = PublishSubject<[Model]>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.generateButton)
        self.collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        self.collectionView.register(Cell.self, forCellWithReuseIdentifier: Cell.identifier)
        self.collectionView.delegate = self
        self.view.addSubview(self.collectionView)
        
        self.generateButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
        }
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.generateButton.snp.bottom)
            make.leading.bottom.trailing.equalToSuperview()
        }
        
        self.bind()
        
        self.generate()
    }
    
    func bind() {
        
        self.generateButton.rx.tap
            .asDriver()
            .drive(onNext: { _ in
                self.generate()
            })
            .disposed(by: self.bag)
        
        self.items
            .asObservable()
            .map({ values in
                values.map({ ViewModel($0) })
            })
            .asDriver(onErrorJustReturn: [])
            .drive(self.collectionView.rx.items(cellIdentifier: Cell.identifier, cellType: Cell.self)) { (_, viewModel, cell) in
                cell.viewModel = viewModel
            }
            .disposed(by: self.bag)
        
    }
    
    func generate() {
        self.items.onNext(
            (0..<20).map({ _ in Int.random(in: 0..<100) }).map({ Model($0) })
        )
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

extension ViewController {
    class Cell : UICollectionViewCell {
        class var identifier: String { return "\(self)" }
        
        var bag = DisposeBag()
        
        let label = UILabel()
        let plus = UIButton.image(#imageLiteral(resourceName: "plus"))
        let minus = UIButton.image(#imageLiteral(resourceName: "minus"))
        let delete = UIButton.image(#imageLiteral(resourceName: "delete"))
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.ui()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func ui() {
            let stackView = UIStackView(arrangedSubviews: [
                self.label,
                self.plus,
                self.minus,
                self.delete
                ])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.spacing = 8
            self.contentView.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        var viewModel: ViewModel? = nil {
            didSet {
                self.bag = DisposeBag()
                guard let viewModel = self.viewModel else {
                    self.label.text = nil
                    return
                }
                
                viewModel.value
                    .map({ "number is \($0.number)" })
                    .asDriver(onErrorJustReturn: "")
                    .drive(self.label.rx.text)
                    .disposed(by: self.bag)
                
                self.plus.rx.tap
                    .asDriver()
                    .drive(onNext: { _ in
                        print("plus tapped")
                    })
                    .disposed(by: self.bag)
                
                self.minus.rx.tap
                    .asDriver()
                    .drive(onNext: { _ in
                        print("minus tapped")
                    })
                    .disposed(by: self.bag)
                
                self.delete.rx.tap
                    .asDriver()
                    .drive(onNext: { _ in
                        print("plus delete")
                    })
                    .disposed(by: self.bag)
            }
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            self.bag = DisposeBag()
            self.viewModel = nil
        }
    }
}

extension ViewController {
    
    class Model {
        var number: Int

        init(_ n: Int = 0) {
            self.number = n
        }
    }
    
    class ViewModel {
        
        var value: Observable<Model>
        
        init(_ model: Model) {
            self.value = Observable.just(model)
        }
    }
    
}
