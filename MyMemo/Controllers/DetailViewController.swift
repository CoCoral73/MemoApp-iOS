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
    
    private lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareButtonTapped))
        return button
    }()
    private lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(saveButtonTapped))
        return button
    }()
    
    private lazy var menuOfUnlockState: UIMenu = {
        let menu = UIMenu(children: [
            UIAction(title: "메모 잠금", image: UIImage(systemName: "lock"), handler: self.lockButtonTapped),
            UIAction(title: "메모 이동", image: UIImage(systemName: "folder"), handler: self.moveButtonTapped),
            UIAction(title: "메모 삭제", image: UIImage(systemName: "trash")?.withTintColor(.red, renderingMode: .alwaysOriginal), handler: self.removeButtonTapped)
            ])
        return menu
    }()
    private lazy var menuOfLockState: UIMenu = {
        let menu = UIMenu(children: [
            UIAction(title: "메모 잠금 해제", image: UIImage(systemName: "lock.open"), handler: self.unlockButtonTapped),
            UIAction(title: "메모 이동", image: UIImage(systemName: "folder"), handler: self.moveButtonTapped),
            UIAction(title: "메모 삭제", image: UIImage(systemName: "trash")?.withTintColor(.red, renderingMode: .alwaysOriginal), handler: self.removeButtonTapped)
            ])
        return menu
    }()
    private lazy var menuButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menuOfUnlockState)
        return button
    }()
    
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    let coreDataManager = CoreDataManager.shared

    //nil일 수도 있고, 아닐 수도 있음
    var memo: Memo? {
        didSet {
            tmpColor = memo?.color
        }
    }
    //버그 나지 않는 이상 무조건 값이 있음
    var folder: Folder?
    
    //메모뷰의 + -> 디테일뷰인 상태일 때 사용
    var completionOfAdd: (DetailViewController) -> Memo? = { (sender) in return nil }
    //디테일뷰 내에서 메모의 이동과 삭제가 이루어졌을 때(폴더 이동) 사용
    var completionOfMoveAndRemove: (DetailViewController) -> Void = { (sender) in }
    //디테일뷰 내에서 메모를 상태변경(색 변경, 잠금) 했을 때 사용
    var completionOfChangeState: (DetailViewController) -> Void = { (sender) in }
    
    var tmpColor: Int64? = 1
    var nowDate: Date?  //새로운 모드가 생성될 때 값이 할당됨
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setup()
        configureUIwithMode()
        setupBarButtonItems()
    }
    
    func setup() {
        guard let folder = self.folder else { return }
        
        //텍스트뷰 설정
        textView.delegate = self
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        
        //색 선택 버튼 세팅
        (0..<5).forEach {
            buttons[$0].backgroundColor = MemoColor(rawValue: Int64($0 + 1))!.backgroundColor
            
            buttons[$0].isEnabled = !folder.isTrash
        }
    }
    
    func configureUIwithMode() {
        //휴지통에 있는 메모는 텍스트 편집 불가, 저장 버튼 타이틀 설정
        if let memo = self.memo, memo.folder.isTrash {
            textView.isEditable = false
            saveButton.title = "복원"
        } else {
            textView.isEditable = true
            saveButton.title = "완료"
        }

        if let memo = self.memo {
            //수정 모드 or 휴지통 모드
            let color = MemoColor(rawValue: memo.color)
            setColorTheme(color: color)
            
            //메모 저장할 때 텍스트가 textView.text로 전달되는데 String! 타입임
            //메모가 존재한다면 text 값은 항상 값이 있을 것.
            guard let text = memo.text else { return }
            textView.text = text
            
            //폴더는 항상 값이 있을 것.
            guard let folder = self.folder else { return }
            if folder.isTrash { //휴지통 모드
                dateLabel.text = memo.deletedDateString
            } else { //수정 모드
                dateLabel.text = memo.dateString
            }
        } else {
            //생성 모드
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
    
    func setupBarButtonItems() {
        //폴더는 항상 값이 있을 것.
        guard let folder = self.folder else { return }
        
        shareButton.isEnabled = !textView.text.isEmpty
        
        if let memo = self.memo {
            if folder.isTrash { //휴지통 모드
                self.navigationItem.rightBarButtonItems = [saveButton]
            } else {    //수정 모드
                menuButton.menu = memo.password == nil ? menuOfUnlockState : menuOfLockState
                self.navigationItem.rightBarButtonItems = [menuButton, shareButton]
            }
        } else { //생성 모드
            self.navigationItem.rightBarButtonItems = [saveButton, shareButton]
        }
    }
    
    func setColorTheme(color: MemoColor? = .pink) {
        view.backgroundColor = color?.backgroundColor
    }
    
    @IBAction func colorButtonTapped(_ sender: UIButton) {
        let tagValue = Int64(sender.tag)
        self.tmpColor = tagValue
        
        setColorTheme(color: MemoColor(rawValue: tagValue))
        
        if let memo = self.memo {
            memo.color = self.tmpColor ?? 1
            coreDataManager.updateMemo(memo: memo) { }
        }
        completionOfChangeState(self)
    }
    
    @objc func shareButtonTapped() {
        let textToShare = textView.text
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        
        // iPad의 경우 popoverPresentationController 설정 필요
        if let popover = activityViewController.popoverPresentationController {
            popover.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func saveButtonTapped() {
        if saveButton.title == "완료" {
            if let memo = self.memo {   //수정 모드
                if textView.text.isEmpty {
                    coreDataManager.deleteEmptyMemo(memo: memo) {
                        self.completionOfMoveAndRemove(self)
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    memo.text = textView.text
                    memo.color = tmpColor ?? 1
                    coreDataManager.updateMemo(memo: memo) { }
                    self.completionOfChangeState(self)
                }
            } else {    //생성 모드
                if textView.text.isEmpty { // 텍스트뷰가 비어있음 -> 저장 안함
                    self.navigationItem.rightBarButtonItems = [shareButton]
                    textView.resignFirstResponder()
                    return
                }
                
                //저장 처리
                guard let folder = self.folder else { return }
                coreDataManager.addMemo(text: textView.text, color: tmpColor ?? 1, folder: folder, date: nowDate) {
                    //중복 저장 방지, 메모 뷰의 가장 최근 메모를 반환 받음
                    self.memo = self.completionOfAdd(self)
                }
            }
            textView.resignFirstResponder()
            self.navigationItem.rightBarButtonItems = [menuButton, shareButton]
        } else if saveButton.title == "복원" {    //휴지통 모드
            //이동할 폴더 선택
            performSegue(withIdentifier: Segue.moveMemoInDetailViewIdentifier, sender: self)
        }
        
    }
    
    func lockButtonTapped(_ action: UIAction) {
        performSegue(withIdentifier: Segue.lockMemoIdentifier, sender: self)
    }
    
    func unlockButtonTapped(_ action: UIAction) {
        guard let memo = self.memo else { return }
        let alert = UIAlertController(title: "잠금 해제", message: "해당 메모의 잠금을 해제하겠습니까?", preferredStyle: .alert)
    
        let ok = UIAlertAction(title: "확인", style: .default) { [weak self] action in
            guard let self = self else { return }
            memo.password = nil
            memo.hint = nil
            self.coreDataManager.updateMemo(memo: memo) {
                
            }
            self.menuButton.menu = self.menuOfUnlockState
            self.completionOfChangeState(self)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func moveButtonTapped(_ action: UIAction) {
        performSegue(withIdentifier: Segue.moveMemoInDetailViewIdentifier, sender: self)
    }
    
    func removeButtonTapped(_ action: UIAction) {
        guard let memo = self.memo else { return }
        let alert = UIAlertController(title: "메모 삭제", message: "삭제한 메모는 휴지통으로 이동됩니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            // 예시: 데이터 배열 및 Core Data 삭제 처리
            
            let memoToRemove = memo
            self.coreDataManager.removeMemo(memo: memoToRemove) {
                self.completionOfMoveAndRemove(self)
            }
            self.navigationController?.popViewController(animated: true)
        }))
        
        // 현재 뷰 컨트롤러에서 alert 표시
        self.present(alert, animated: true, completion: nil)
    }
    
    //휴지통에서 복원, 메뉴 버튼에서 메모 이동
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.moveMemoInDetailViewIdentifier {
            let moveVC = segue.destination as! MoveViewController
            guard let memo = self.memo else { return }
            moveVC.memos = [memo]
            moveVC.folder = self.folder
            moveVC.completionMove = { (sender) in
                self.completionOfMoveAndRemove(self)
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        if segue.identifier == Segue.lockMemoIdentifier {
            let lockVC = segue.destination as! LockViewController
            guard let memo = self.memo else { return }
            lockVC.memo = memo
            lockVC.completionLock = { (sender) in
                self.menuButton.menu = self.menuOfLockState
                self.completionOfChangeState(self)
            }
        }
    }
}

extension DetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        //저장 버튼 생성
        if let _ = self.memo {  //수정 모드
            self.navigationItem.rightBarButtonItems = [saveButton, menuButton, shareButton]
        } else if let items = self.navigationItem.rightBarButtonItems, !items.contains(saveButton) {    //생성 모드에서 저장 안 된 채로 다시 편집할 때
            self.navigationItem.rightBarButtonItems = [saveButton, shareButton]
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        shareButton.isEnabled = !textView.text.isEmpty
    }
}
