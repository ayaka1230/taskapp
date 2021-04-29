//
//  Task.swift
//  taskapp
//
//  Created by 長坂絢加 on 2021/04/28.
//

import Foundation

import RealmSwift

class Task: Object {
    // 管理用 ID。プライマリーキー
    @objc dynamic var id = 0
    
    // タイトル
    @objc dynamic var title = ""
    
    // 内容
    @objc dynamic var contents = ""
    
    // 日時
    @objc dynamic var date = Date()
    
    // カテゴリ
    @objc dynamic var category: Category?
    
    // id をプライマリーキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
}
