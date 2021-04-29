//
//  Category.swift
//  taskapp
//
//  Created by 長坂絢加 on 2021/04/29.
//

import RealmSwift

class Category: Object {
    // 管理用 ID。プライマリーキー
    @objc dynamic var id = 0
    
    // カテゴリ名
    @objc dynamic var name = ""
    
    // id をプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}

