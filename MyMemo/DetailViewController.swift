//
//  DetailViewController.swift
//  MyMemo
//
//  Created by 김정원 on 2/20/25.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var pinkButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var purpleButton: UIButton!
    
    lazy var buttons: [UIButton] = {
        return [pinkButton, yellowButton, greenButton, blueButton, purpleButton]
    }()
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    let coreDataManager = CoreDataManager.shared

    var memo: Memo? {
        didSet {
            tmpColor = memo?.color
        }
    }
    var folder: Folder?
    var memoFetch: (DetailViewController) -> Memo? = { (sender) in return nil }
    
    var tmpColor: Int64? = 1
    var nowDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setup()
        configureUI()
    }
    
    func setup() {
        textView.delegate = self
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        
        //휴지통에 있는 메모는 텍스트 편집 불가
        if let memo = self.memo, memo.folder.isTrash {
            textView.isEditable = false
            saveButton.title = "복원"
        } else {
            textView.isEditable = true
            saveButton.title = "저장"
        }
        
        //버튼 색 세팅
        (0..<5).forEach {
            buttons[$0].backgroundColor = MemoColor(rawValue: Int64($0 + 1))!.backgroundColor
        }
    }
    
    func configureUI() {

        if let memo = self.memo {
            //수정 모드
            let color = MemoColor(rawValue: memo.color)
            setColorTheme(color: color)
            
            guard let text = memo.text else { return }
            textView.text = text
            
            guard let folder = self.folder else { return }
            if folder.isTrash {
                dateLabel.text = memo.deletedDateString
            } else {
                dateLabel.text = memo.dateString
            }
        } else {
            //새로운 메모 모드
            setColorTheme()
            textView.becomeFirstResponder()
            
            nowDate = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 M월 d일 a h:mm"
            guard let nowDate = nowDate else {
                dateLabel.text = ""
                return
            }
            dateLabel.text = formatter.string(from: nowDate)
        }
        
    }
    
    func setColorTheme(color: MemoColor? = .pink) {
        view.backgroundColor = color?.backgroundColor
        
        //수정 필요
        //navigationController?.navigationBar.barTintColor = color?.navigationBarColor
    }
    
    @IBAction func colorButtonTapped(_ sender: UIButton) {
        
        self.tmpColor = Int64(sender.tag)
        
        let color = MemoColor(rawValue: Int64(sender.tag))
        setColorTheme(color: color)
    
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        if saveButton.title == "저장" {
            if let memo = self.memo {
                memo.text = textView.text
                memo.color = tmpColor ?? 1
                coreDataManager.updateMemo(memo: memo) {
                    
                }
            } else {
                let text = textView.text
                if (text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                    // 텍스트뷰가 비어있거나 공백, 개행 문자만 포함되어 있음 -> 저장 안함
                    return
                }
                
                guard let folder = self.folder else { return }
                coreDataManager.addMemo(text: text, color: tmpColor ?? 1, folder: folder, date: nowDate) {
                    //중복 저장 방지
                    self.memo = self.memoFetch(self)
                }
            }
            textView.resignFirstResponder()
        } else if saveButton.title == "복원" {
            //이동할 폴더 선택
            performSegue(withIdentifier: Segue.moveMemoInDetailViewIdentifier, sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.moveMemoInDetailViewIdentifier {
            let moveVC = segue.destination as! MoveViewController
            guard let memo = self.memo else { return }
            moveVC.memos = [memo]
            moveVC.folder = self.folder
            moveVC.completionMove = { (sender) in
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension DetailViewController: UITextViewDelegate {
    
}
