//
//  CategoryViewController.swift
//  taskapp
//
//  Created by 長坂絢加 on 2021/04/29.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var categoryTextField: UITextField!
    
    @IBOutlet weak var addButton: UIButton!
    
    let realm = try! Realm()
    var category: Category!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        categoryTextField.delegate = self
        // 最初は追加ボタンを非活性にしておく
        addButton.isEnabled = false
        // 背景をタップしたら dismissKeyboard メソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    // UITextField のリターンをタップした時に実行されるメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    // UITextField に文字を追加・削除した時に呼び出されるメソッド
    @IBAction func textEditDidChange(_ sender: Any) {
        // 何も入力されていない場合は追加ボタンを非活性にする
        if categoryTextField.text!.count > 0 {
            addButton.isEnabled = true
        } else {
            addButton.isEnabled = false
        }
    }
    
    // 追加ボタンがタップされた時に呼び出されるメソッド
    @IBAction func tapAddButton(_ sender: Any) {
        let allCategories = realm.objects(Category.self)
        let nextId = allCategories.count + 1
        self.category = Category()
        try! realm.write {
            self.category.id = nextId
            self.category.name = categoryTextField.text!
            self.realm.add(self.category, update: .modified)
        }

    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
