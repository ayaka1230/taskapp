//
//  ViewController.swift
//  taskapp
//
//  Created by 長坂絢加 on 2021/04/26.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var categoryTextField: UITextField!

    @IBOutlet weak var tableView: UITableView!
    
    var categoryPicker = UIPickerView()
    
    // Realm インスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト
    // 日時の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)

    // DB内のカテゴリが格納されるリスト
    // id でソート：昇順
    // 以降内容をアップデートすると自動的に更新される
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        categoryTextField.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        self.createCategoryPickerView()
    }
    
    // カテゴリの Picker を作成するメソッド
    func createCategoryPickerView() {
        categoryPicker.delegate = self
        categoryTextField.inputView = categoryPicker
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePicker))
        toolbar.setItems([doneButtonItem], animated: true)
        categoryTextField.inputAccessoryView = toolbar
    }
    
    // Picker の done をタップした時に呼ばれるメソッド
    @objc func donePicker() {
        // Picker を閉じる
        categoryTextField.endEditing(true)
    }
    
    // categoryTextField の clear button をタップした時に呼ばれるメソッド
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.resetTaskArray()
        self.resetPickerSelected()
        return true
    }
    
    // segue で画面遷移する時に呼ばれるメソッド
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        // 遷移する時にピッカーは閉じる
        self.donePicker()
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
        }
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
    }
    
    // 入力画面から戻ってきた時に呼ばれるメソッド
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // categoryTextField をリセット
        categoryTextField.text = ""
        self.resetTaskArray()
        self.resetPickerSelected()
    }
    
    // taskArray をリセットするメソッド
    func resetTaskArray() {
        taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        tableView.reloadData()
    }
    
    // Picker の選択をリセットするメソッド
    func resetPickerSelected() {
        self.categoryPicker.selectRow(0, inComponent: 0, animated: true)
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
    
    // カテゴリが選択された時に呼ばれるメソッド
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // 選択しているカテゴリ名を categoryTextField に表示する
        categoryTextField.text = categoryArray[row].name
        // 選択したカテゴリでフィルタする
        let selectedCategoryIndex = categoryPicker.selectedRow(inComponent: 0)
        let selectedCategory = categoryArray[selectedCategoryIndex]
        taskArray = realm.objects(Task.self).filter("category == %@", selectedCategory)
        tableView.reloadData()
    }

    // データの数(=セルの数)を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        let task = taskArray[indexPath.row]
        cell.titleLabel.text = task.title

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString: String = formatter.string(from: task.date)
        cell.dateLabel.text = dateString
        
        cell.categoryLabel.text = task.category?.name

        return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
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
    }

}

