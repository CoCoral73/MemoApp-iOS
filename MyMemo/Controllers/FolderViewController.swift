//
//  FolderViewController.swift
//  MyMemo
//
//  Created by 김정원 on 2/18/25.
//

import UIKit

class FolderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolBar: UIToolbar!
    private lazy var editButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "편집", style: .plain, target: self, action: #selector(editButtonTapped))
        button.tintColor = .systemOrange
        return button
    }()
    private lazy var addButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), style: .plain, target: self, action: #selector(addFolderButtonTapped))
        button.tintColor = .systemOrange
        return button
    }()
    let flexibleSpace = UIBarButtonItem.flexibleSpace()
    
    let coreDataManager = CoreDataManager.shared
    
    var folders: [Folder] = []
    var folderNameList: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableview()
        fetchFolders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func setupUI() {
        view.backgroundColor = MemoColor.base.backgroundColor
        
        setupBar()
    }
    
    func setupBar() {
        self.title = "폴더"
        
        toolBar.barTintColor = MemoColor.base.backgroundColor
        toolBar.setItems([editButton, flexibleSpace, addButton], animated: true)
        
        if let navigationBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            // 기본 배경 및 기타 스타일 초기화
            appearance.configureWithOpaqueBackground()
            // 배경 색상 설정
            appearance.backgroundColor = MemoColor.base.backgroundColor
            // 타이틀 텍스트 색상 설정
            appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
            appearance.shadowColor = .clear
        
            navigationBar.standardAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    func setupTableview() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.backgroundColor = MemoColor.base.backgroundColor
        tableView.rowHeight = 45
    }
    
    func fetchFolders() {
        folders = coreDataManager.getFolderListFromCoreData()
        folderNameList = Set(folders.map { $0.name ?? "" })
    }

    @objc func editButtonTapped() {
        if tableView.isEditing { //편집 종료
            editButton.title = "편집"
            toolBar.setItems([editButton, flexibleSpace, addButton], animated: true)
            setEditing(false, animated: true)
        } else { //편집모드 활성화
            editButton.title = "완료"
            toolBar.setItems([editButton, flexibleSpace], animated: true)
            setEditing(true, animated: true)
        }
    }
    
    @objc func addFolderButtonTapped() {
        //폴더 생성 얼럿 띄우기
        let alert = UIAlertController(title: "새로운 폴더", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "생성할 폴더의 이름을 입력하세요"
            tf.clearButtonMode = .whileEditing
            tf.addTarget(self, action: #selector(self.folderNameChanged), for: .editingChanged)
        }
        
        let success = UIAlertAction(title: "완료", style: .default) { action in
            if let folderName = alert.textFields?[0].text {
                self.coreDataManager.addFolder(name: folderName) {
                    self.fetchFolders()
                    self.tableView.reloadData()
                }
            }
        }
        //처음엔 빈 문자열이니까 사용 불가
        success.isEnabled = false
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(success)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func folderNameChanged(_ textField: UITextField) {
        guard let alert = self.presentedViewController as? UIAlertController,
              let folderName = textField.text,
              let addAction = alert.actions.first(where: { $0.title == "완료" }) else { return }
        
        // 예: 이미 존재하는 폴더명 확인 (yourFolderNames는 이미 존재하는 폴더 이름 배열)
        let folderAlreadyExists = folderNameList.contains { $0.caseInsensitiveCompare(folderName) == .orderedSame }
        
        // 입력값이 비어있거나, 이미 존재한다면 확인 버튼을 비활성화하고, 인라인 피드백(예: 텍스트필드 배경색 변경)을 제공할 수 있음.
        if folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addAction.isEnabled = false
            alert.message = "유효하지 않은 폴더명"
        } else if folderAlreadyExists {
            addAction.isEnabled = false
            alert.message = "중복된 폴더명"
        } else {
            addAction.isEnabled = true
            alert.message = ""
        }
    }
    
}

extension FolderViewController: UITableViewDelegate, UITableViewDataSource {
    //DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return folders.count - 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.folderCellIdentifier, for: indexPath) as! FolderCell
        
        let folder: Folder
        if indexPath.section == 0 {
            folder = folders[indexPath.row]
        } else {
            folder = folders[indexPath.row + 2]
        }
        
        cell.editMode = tableView.isEditing
        cell.folder = folder
        
        return cell
    }
    
    
    
    //Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Segue.folderToMemoIdentifier, sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.folderToMemoIdentifier {
            let memoVC = segue.destination as! MemoViewController
            
            guard let indexPath = sender as? IndexPath else { return }
            let folders = coreDataManager.getFolderListFromCoreData()
            if indexPath.section == 0 {
                memoVC.myFolder = folders[indexPath.row]
            } else {
                memoVC.myFolder = folders[indexPath.row + 2]
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        tableView.allowsSelection = !editing
        
        for cell in tableView.visibleCells {
            if let myCell = cell as? FolderCell {
                myCell.configureUI(editing)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            return .none
        } else {
            return .delete
        }
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == 1 {
            let alert = UIAlertController(title: "폴더 삭제", message: "폴더는 삭제되지만\n메모는 휴지통으로 이동됩니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                // 예시: 데이터 배열 및 Core Data 삭제 처리
                let deleteIndex = indexPath.row + 2  // 섹션 0 보정
                let folderToDelete = self.folders[deleteIndex]
                self.coreDataManager.deleteFolder(folder: folderToDelete) {
                    self.fetchFolders()
                    self.tableView.reloadData()
                }
            }))
            
            // 현재 뷰 컨트롤러에서 alert 표시
            self.present(alert, animated: true, completion: nil)
        }
    }
}
