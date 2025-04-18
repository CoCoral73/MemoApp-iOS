//
//  LockViewController.swift
//  MyMemo
//
//  Created by 김정원 on 3/4/25.
//

import UIKit

class LockViewController: UIViewController {
    
    let coreDataManager = CoreDataManager.shared
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var pwTf1: UITextField!
    @IBOutlet weak var pwTf2: UITextField!
    @IBOutlet weak var pwLabel: UILabel!
    @IBOutlet weak var hintTf: UITextField!
    
    var memo: Memo?
    var completionLock: (LockViewController) -> Void = { (sender) in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextField()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        pwLabel.isHidden = true
        saveButton.isEnabled = false
    }
    
    func setupTextField() {
        pwTf1.delegate = self
        pwTf2.delegate = self
        hintTf.delegate = self
        
        pwTf1.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        pwTf2.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        pwTf1.becomeFirstResponder()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text1 = pwTf1.text, let text2 = pwTf2.text, !text1.isEmpty && !text2.isEmpty {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        guard let memo = self.memo else { return }
        
        if pwTf1.text == pwTf2.text {
            memo.password = pwTf2.text
            memo.hint = hintTf.text ?? ""
            coreDataManager.updateMemo(memo: memo) {
                
            }
            completionLock(self)
            dismiss(animated: true)
        } else {
            pwLabel.isHidden = false
        }
    }
    
}

extension LockViewController: UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == pwTf1 {
            pwTf2.becomeFirstResponder()
        } else if textField == pwTf2 {
            hintTf.becomeFirstResponder()
            pwLabel.isHidden = pwTf1.text == pwTf2.text
        } else if textField == hintTf {
            hintTf.resignFirstResponder()
        }
        return true
    }
}
