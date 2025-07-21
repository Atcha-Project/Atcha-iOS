//
//  MyPageCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import UIKit

final class MyPageCell: UICollectionViewCell {
    static let identifier = "MyPageCell"
    private var atchaList: AtchaList?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        atchaList?.removeFromSuperview()
        atchaList = nil
    }
    
    func configure(with item: MyPageProtocol) {
        let list = AtchaList(title: item.title, listType: item.type)
        contentView.addSubview(list)
        list.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        atchaList = list
    }
}
