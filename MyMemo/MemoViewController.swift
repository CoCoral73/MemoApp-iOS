//
//  MemoViewController.swift
//  MyMemo
//
//  Created by 김정원 on 2/20/25.
//

import UIKit

class MemoViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var toolBar: UIToolbar!
    private lazy var editButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "편집", style: .plain, target: self, action: #selector(editButtonTapped))
        return button
    }()
    
    //left button 편집 모드일 때만 활성화
    private lazy var moveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "이동", style: .plain, target: self, action: #selector(moveButtonTapped))
        return button
    }()
    private lazy var moveAllButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "모두 이동", style: .plain, target: self, action: #selector(moveAllButtonTapped))
        return button
    }()
    
    let flexibleSpace = UIBarButtonItem.flexibleSpace()
    
    //right button
    private lazy var addButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        return button
    }()
    private lazy var clearButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "비우기", style: .plain, target: self, action: #selector(clearButtonTapped))
        return button
    }()
    private lazy var removeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "삭제", style: .plain, target: self, action: #selector(removeButtonTapped))
        button.tintColor = .red
        return button
    }()
    private lazy var removeAllButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "모두 삭제", style: .plain, target: self, action: #selector(removeAllButtonTapped))
        button.tintColor = .red
        return button
    }()
    
    let coreDataManager = CoreDataManager.shared
    
    var memos: [Memo] = []
    var myFolder: Folder?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchMemos()
        setupUI()
        setupTableview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func fetchMemos() {
        guard let myFolder = myFolder else { return }
        memos = coreDataManager.getMemoListFromCoreData(selectedFolder: myFolder)
        
        setupNavigationBar()
    }
    
    func setupUI() {
        guard let myFolder = myFolder else { return }
        self.title = myFolder.name
        
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        toolBar.barTintColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        clearButton.tintColor = .red
        
        setupToolbarItems()
    }
    
    func setupTableview() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
    }
    
    func setupToolbarItems() {
        guard let myFolder = myFolder else { return }
        guard var items = toolBar.items else { return }
        if myFolder.isTrash { //휴지통일 때
            if memos.isEmpty {
                items = []
            } else {
                if isEditing {
                    let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
                    if selectedCount > 0 {
                        items = [moveButton, flexibleSpace, removeButton]
                    } else {
                        items = [moveAllButton, flexibleSpace]
                    }
                    
                } else {
                    items = [flexibleSpace, clearButton]
                }
            }
        } else { //일반 폴더
            if isEditing {
                let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
                if selectedCount > 0 {
                    items = [moveButton, flexibleSpace, removeButton]
                } else {
                    items = [moveAllButton, flexibleSpace, removeAllButton]
                }
            } else {
                items = [flexibleSpace, addButton]
            }
        }
        toolBar.setItems(items, animated: true)
    }
    
    func setupNavigationBar() {
        if memos.isEmpty {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.navigationItem.rightBarButtonItem = editButton
        }
    }
    
    
    @objc func editButtonTapped(_ sender: UIBarButtonItem) {
        if tableView.isEditing { //편집 종료
            editButton.title = "편집"
            setEditing(false, animated: true)
        } else { //편집모드 활성화
            editButton.title = "완료"
            setEditing(true, animated: true)
        }
        setupToolbarItems()
    }

    
    @objc func moveButtonTapped() {
        //선택 이동
        var memosToMove: [Memo] = []
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            for indexPath in selectedIndexPaths {
                guard let cell = tableView.cellForRow(at: indexPath) as? MemoCell else { return }
                guard let memo = cell.memo else { return }
                memosToMove.append(memo)
            }
        }
        performSegue(withIdentifier: Segue.moveMemoInMemoViewIdentifier, sender: memosToMove)
    }
    
    @objc func moveAllButtonTapped() {
        //모두 이동
        let memosToMove = self.memos
        performSegue(withIdentifier: Segue.moveMemoInMemoViewIdentifier, sender: memosToMove)
    }
    
    @objc func addButtonTapped() {
        performSegue(withIdentifier: Segue.memoToDetailIdentifier, sender: nil)
    }
    
    @objc func clearButtonTapped() {
        let alert = UIAlertController(title: "\(memos.count)개의 메모를 영구적으로 지우겠습니까?", message: "이 동작은 실행 취소할 수 없습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "휴지통 비우기", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            // 예시: 데이터 배열 및 Core Data 삭제 처리

            self.coreDataManager.deleteAllMemoFromTrash {
                self.fetchMemos()
                self.tableView.reloadData()
                self.setupToolbarItems()
            }
        }))
        
        // 현재 뷰 컨트롤러에서 alert 표시
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func removeButtonTapped() {
        guard let myFolder = self.myFolder else { return }
        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        let title = myFolder.isTrash ? "영구 삭제" : "삭제"
        let message = myFolder.isTrash ? "이 동작은 실행 취소할 수 없습니다." : "삭제한 메모는 휴지통으로 이동됩니다."
        
        let alert = UIAlertController(title: "\(selectedCount)개의 메모 \(title)", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: title, style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
        
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                for indexPath in selectedIndexPaths {
                    guard let cell = tableView.cellForRow(at: indexPath) as? MemoCell else { return }
                    guard let memo = cell.memo else { return }
                    if myFolder.isTrash {
                        self.coreDataManager.deleteMemoFromTrash(memo: memo) {
                            
                        }
                    } else {
                        self.coreDataManager.deleteMemo(memo: memo) {
                            
                        }
                    }
                }
            }
            
            self.fetchMemos()
            self.tableView.reloadData()
        }))
        
        // 현재 뷰 컨트롤러에서 alert 표시
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func removeAllButtonTapped() {
        let alert = UIAlertController(title: "\(memos.count)개의 메모 삭제", message: "삭제한 메모는 휴지통으로 이동됩니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            guard let myFolder = self.myFolder else { return }
            // 예시: 데이터 배열 및 Core Data 삭제 처리
            
            self.coreDataManager.deleteAllMemoFromFolder(folder: myFolder) {
                self.fetchMemos()
                self.tableView.reloadData()
            }
        }))
        
        // 현재 뷰 컨트롤러에서 alert 표시
        self.present(alert, animated: true, completion: nil)
    }

}

extension MemoViewController: UITableViewDelegate, UITableViewDataSource {
    //DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let myFolder = myFolder else { return 0 }
        return coreDataManager.getMemoListFromCoreData(selectedFolder: myFolder).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.memoCellIdentifier, for: indexPath) as! MemoCell
        
        guard let myFolder = myFolder else { return cell }
        
        let memos = coreDataManager.getMemoListFromCoreData(selectedFolder: myFolder)
        cell.memo = memos[indexPath.row]
        
        return cell
    }
    
    //Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            setupToolbarItems()
            return
        }
        performSegue(withIdentifier: Segue.memoToDetailIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            setupToolbarItems()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.memoToDetailIdentifier {
            let detailVC = segue.destination as! DetailViewController
            
            guard let myFolder = myFolder else { return }
            detailVC.folder = myFolder
            detailVC.memoFetch = { (sender) in
                self.fetchMemos()
                return self.memos.first
            }
            
            //셀 선택 시에만 아래 코드 실행
            guard let indexPath = sender as? IndexPath else { return }
            let memos = coreDataManager.getMemoListFromCoreData(selectedFolder: myFolder)
            detailVC.memo = memos[indexPath.row]
            
            return
        }
        
        if segue.identifier == Segue.moveMemoInMemoViewIdentifier {
            let moveVC = segue.destination as! MoveViewController
            guard let memosToMove = sender as? [Memo] else { return }
            moveVC.memos = memosToMove
            moveVC.folder = self.myFolder
            moveVC.completionMove = { (sender) in
                self.fetchMemos()
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "메모 삭제", message: "삭제한 메모는 휴지통으로 이동됩니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                // 예시: 데이터 배열 및 Core Data 삭제 처리
                
                let memoToDelete = self.memos[indexPath.row]
                self.coreDataManager.deleteMemo(memo: memoToDelete) {
                    self.fetchMemos()
                    self.tableView.reloadData()
                }
            }))
            
            // 현재 뷰 컨트롤러에서 alert 표시
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
}
