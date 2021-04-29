//
//  InputViewController.swift
//  taskapp
//
//  Created by 長坂絢加 on 2021/04/27.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryPicker: UIPickerView!
    
    let realm = try! Realm()
    var task: Task!

    // DB内のカテゴリが格納されるリスト
    // id でソート：昇順
    // 以降内容をアップデートすると自動的に更新される
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleTextField.delegate = self
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        setDefaultCategory()
        
        // 背景をタップしたら dismissKeyboard メソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        // タスクのカテゴリが存在する場合（＝セルをタップして遷移してきた場合）、Picker を合わせておく
        if task.category != nil {
            let targetCategoryIndex = categoryArray.index(of: task.category!)
            self.categoryPicker.selectRow(targetCategoryIndex!, inComponent: 0, animated: true)
        }
    }
    
    // カテゴリが何も設定されていない場合、カテゴリに「なし」を追加しておくメソッド
    func setDefaultCategory() {
        let category = Category()
        if categoryArray.count == 0 {
            try! realm.write {
                category.id = 1
                category.name = "なし"
                self.realm.add(category, update: .modified)
            }
        }
        categoryPicker.reloadAllComponents()
    }
    
    // カテゴリ追加画面から戻ってきた時に呼ばれるメソッド
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryPicker.reloadAllComponents()
    }
    
    // Picker の列数の設定
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Picker の行とデータ要素数の設定
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }
    
    // Picker のデータを設定
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryArray[row].name
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
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
    
    // 保存ボタンがタップされた時に呼び出されるメソッド
    @IBAction func tapSaveButton(_ sender: Any) {

        let selectedCategoryIndex = categoryPicker.selectedRow(inComponent: 0)

        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category = self.categoryArray[selectedCategoryIndex]
            self.realm.add(self.task, update: .modified)
        }
        setNotification(task: task)
    }
    
    
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージなしで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        content.sound = UNNotificationSound.default
        
        // ローカル通知が発動する trigger(日付マッチ)を作成
        let calander = Calendar.current
        let dateComponents = calander.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // identifier, content, trigger からローカル通知を作成(identifier が同じだとローカル通知を上書き保存)
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)
        
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            // error が nil ならローカル通知の登録に成功したと表示します。error が存在すればエラーを表示します。
            print(error ?? "ローカル通知登録 OK")
        }
        
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests{ (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
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
