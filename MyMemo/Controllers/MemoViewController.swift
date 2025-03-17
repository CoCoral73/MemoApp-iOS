//
//  MemoViewController.swift
//  MyMemo
//
//  Created by 김정원 on 2/20/25.
//

import UIKit

class MemoViewController: UIViewController {

    let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"))
    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(doneButtonTapped))
        return button
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var toolBar: UIToolbar!

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
    
    var searchController = UISearchController(searchResultsController: nil)
    
    let coreDataManager = CoreDataManager.shared
    
    var memos: [Memo] = []
    var filteredMemos: [Memo] = []
    
    var myFolder: Folder?
    var folderNameList: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupSearchController()
        setupTableview()
        setupUI()
        fetchMemos()
        setupToolbarItems()
    }
    
    func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false   //검색 시 배경을 흐리게 처리하지 않도록
        searchController.searchBar.placeholder = "검색"
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.setValue("취소", forKey: "cancelButtonText") //cancel 타이틀 변경
        navigationItem.searchController = searchController
        definesPresentationContext = true   //현재 뷰 컨트롤러 내에서 검색 결과가 표시되도록 하는 설정
    }
    
    func setupTableview() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.backgroundColor = MemoColor.base.backgroundColor
    }
    
    func setupUI() {
        guard let myFolder = myFolder else { return }
        self.title = myFolder.name
        
        view.backgroundColor = MemoColor.base.backgroundColor
        toolBar.barTintColor = MemoColor.base.backgroundColor
        toolBar.isTranslucent = false
        clearButton.tintColor = .red    //휴지통 한정
        
        navigationItem.rightBarButtonItem = menuButton
        updateActionOfMenuButton()
    }
    
    func fetchMemos() {
        guard let myFolder = myFolder else { return }
        memos = coreDataManager.getMemoListFromCoreData(selectedFolder: myFolder)
        
        tableView.reloadData()
        updateActionOfMenuButton()
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
    
    func updateActionOfMenuButton() {
        guard let myFolder = myFolder else { return }
        
        var menu: UIMenu
        if myFolder.name == "기본 폴더" || myFolder.name == "휴지통" {
            menu = UIMenu(children: [UIAction(title: "메모 선택", image: UIImage(systemName: "checkmark.circle"), attributes: memos.isEmpty ? [.disabled] : [], handler: self.editButtonTapped)])
        }
        else {
            menu = UIMenu(children: [
                UIAction(title: "이름 변경", image: UIImage(systemName: "pencil"), handler: self.renameButtonTapped),
                UIAction(title: "메모 선택", image: UIImage(systemName: "checkmark.circle"), attributes: memos.isEmpty ? [.disabled] : [], handler: self.editButtonTapped)
            ])
        }

        menuButton.menu = menu
    }
    
    func renameButtonTapped(_ action: UIAction) {
        guard let myFolder = myFolder else { return }
        folderNameList = Set(coreDataManager.getFolderListFromCoreData().map { $0.name ?? "" })
        
        let alert = UIAlertController(title: "폴더 이름 변경", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = myFolder.name
            tf.clearButtonMode = .whileEditing
            tf.addTarget(self, action: #selector(self.folderNameChanged), for: .editingChanged)
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            
            if let newName = alert.textFields?[0].text {
                self.coreDataManager.updateFolderName(folder: myFolder, newName: newName) {
                    
                }
                self.title = newName
            }
        }))
        
        // 현재 뷰 컨트롤러에서 alert 표시
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func folderNameChanged(_ textField: UITextField) {
        guard let alert = self.presentedViewController as? UIAlertController,
              let folderName = textField.text,
              let addAction = alert.actions.first(where: { $0.title == "확인" }) else { return }
        
        let folderAlreadyExists = folderNameList.contains { $0.caseInsensitiveCompare(folderName) == .orderedSame }
        
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
    
    @objc func doneButtonTapped() {
        setEditing(!tableView.isEditing, animated: true)
    }
    
    func editButtonTapped(_ action: UIAction) {
        setEditing(!tableView.isEditing, animated: true)
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
                        self.coreDataManager.removeMemo(memo: memo) {
                            
                        }
                    }
                }
            }
            
            self.fetchMemos()
            self.tableView.reloadData()
            if self.memos.isEmpty {
                self.setEditing(false, animated: true)
            } else {
                self.setupToolbarItems()
            }
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
            
            self.coreDataManager.removeAllMemoFromFolder(folder: myFolder) {
                self.fetchMemos()
                self.tableView.reloadData()
                self.setEditing(false, animated: true)
            }
        }))
        
        // 현재 뷰 컨트롤러에서 alert 표시
        self.present(alert, animated: true, completion: nil)
    }

}

extension MemoViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        filterContentForSearchText(searchText)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredMemos = filterMemos(for: searchText)
        tableView.reloadData()
    }
    
    func filterMemos(for searchText: String) -> [Memo] {
        return memos.filter { memo in
            let text = memo.text ?? ""
            if let _ = memo.password {
                // 암호가 걸려있으면, 텍스트의 첫 줄만 검색 대상
                let firstLine = text.components(separatedBy: "\n").first ?? ""
                return firstLine.localizedCaseInsensitiveContains(searchText)
            } else {
                // 암호가 없는 메모는 전체 텍스트를 검색
                return text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
}

extension MemoViewController: UITableViewDelegate, UITableViewDataSource {
    //DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredMemos.count
        } else {
            return memos.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.memoCellIdentifier, for: indexPath) as! MemoCell
        
        let memo: Memo
        if isFiltering() {
            memo = filteredMemos[indexPath.row]
        } else {
            memo = memos[indexPath.row]
        }
        
        cell.memo = memo
        cell.selectionStyle = .gray
        
        return cell
    }
    
    //Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            setupToolbarItems()
            return
        }
        
        let memo = memos[indexPath.row]
        if let pw = memo.password, let hint = memo.hint {
            let alert = createAskingPWAlert(count: 0, password: pw, hint: hint, indexPath: indexPath)
            present(alert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: Segue.memoToDetailIdentifier, sender: indexPath)
        }
    }
    
    func createAskingPWAlert(count: Int, password: String?, hint: String, indexPath: IndexPath) -> UIAlertController {
        let msg1 = "해당 메모의 암호를 입력하세요.", msg2 = "잘못된 암호입니다. 다시 입력하세요.", msg3 = "\nHINT: \(hint)"
        var message = ""
        if count == 0 {
            message = msg1
        } else if count <= 2 {
            message = msg2
        } else {
            message = msg2 + msg3
        }
        
        let alert = UIAlertController(title: "잠겨진 메모", message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "암호"
            textField.isSecureTextEntry = true
        }

        let success = UIAlertAction(title: "확인", style: .default) { action in
            let inputPW = alert.textFields?[0].text
            if inputPW == password {
                self.performSegue(withIdentifier: Segue.memoToDetailIdentifier, sender: indexPath)
            } else {
                let wrongAlert = self.createAskingPWAlert(count: count + 1, password: password, hint: hint, indexPath: indexPath)
                self.present(wrongAlert, animated: true, completion: nil)
            }
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(success)
        alert.addAction(cancel)
        return alert
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
            detailVC.completionOfAdd = { (sender) in
                self.fetchMemos()
                return self.memos.first
            }
            detailVC.completionOfMoveAndRemove = { (sender) in
                self.fetchMemos()
                self.setupToolbarItems()
            }
            detailVC.completionOfChangeState = { (sender) in
                self.tableView.reloadData()
            }
            
            //셀 선택 시에만 아래 코드 실행
            guard let indexPath = sender as? IndexPath else { return }
            detailVC.memo = memos[indexPath.row]
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        if segue.identifier == Segue.moveMemoInMemoViewIdentifier {
            let moveVC = segue.destination as! MoveViewController
            guard let memosToMove = sender as? [Memo] else { return }
            moveVC.memos = memosToMove
            moveVC.folder = self.myFolder
            moveVC.completionMove = { (sender) in
                self.fetchMemos()
                
                if self.memos.isEmpty {
                    self.setEditing(false, animated: true)
                } else {
                    self.setupToolbarItems()
                }
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
                
                let memoToRemove = self.memos[indexPath.row]
                self.coreDataManager.removeMemo(memo: memoToRemove) {
                    self.fetchMemos()
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
        navigationItem.rightBarButtonItem = editing ? doneButton : menuButton
        tableView.setEditing(editing, animated: animated)
        setupToolbarItems()
    }
    
}
