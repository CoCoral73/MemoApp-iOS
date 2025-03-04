//
//  LockViewController.swift
//  MyMemo
//
//  Created by 김정원 on 3/4/25.
//

import UIKit

class LockViewController: UIViewController {
    
    let coreDataManager = CoreDataManager.shared
    
    @IBOutlet weak var pwTf1: UITextField!
    @IBOutlet weak var pwTf2: UITextField!
    
    @IBOutlet weak var pwLabel: UILabel!
    
    var memo: Memo?
    var completionLock: (LockViewController) -> Void = { (sender) in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextField()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        pwLabel.isHidden = true
    }
    
    func setupTextField() {
        pwTf1.delegate = self
        pwTf2.delegate = self
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        guard let memo = self.memo else { return }
        
        if pwTf1.text == pwTf2.text {
            memo.password = pwTf2.text
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
            pwTf2.resignFirstResponder()
            pwLabel.isHidden = pwTf1.text == pwTf2.text
        }
        return true
    }
}
