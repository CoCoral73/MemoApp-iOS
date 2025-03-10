//
//  MoveViewController.swift
//  MyMemo
//
//  Created by 김정원 on 2/24/25.
//

import UIKit

class MoveViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var moveButton: UIBarButtonItem!
    
    let coreDataManager = CoreDataManager.shared
    
    //이동시키려는 메모
    var memos: [Memo] = []
    
    //이동 작업이 이루어지고 있는 폴더
    var folder: Folder?
    
    //테이블 뷰에 표시할 폴더 리스트
    var folders: [Folder] = []
    
    var completionMove: (MoveViewController) -> Void = { (sender) in }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
        setupTableview()
        fetchFolders()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
    }
    
    func setupNavigationBar() {
        self.title = "폴더 선택"
        
        moveButton.isEnabled = false
    }
    
    func setupTableview() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        tableView.rowHeight = 45
    }
    
    func fetchFolders() {
        folders = coreDataManager.getFolderListFromCoreData()
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func moveButtonTapped(_ sender: UIBarButtonItem) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            guard let cell = tableView.cellForRow(at: selectedIndexPath) as? MoveFolderCell else { return }
            guard let dest = cell.folder else { return }
            
            memos.forEach { memo in
                memo.folder = dest
                coreDataManager.updateMemo(memo: memo) {
                    
                }
            }
            dismiss(animated: true)
            completionMove(self)
        }
    }
}

extension MoveViewController: UITableViewDataSource, UITableViewDelegate {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.moveFolderCellIdentifier, for: indexPath) as! MoveFolderCell
        
        let folder: Folder
        if indexPath.section == 0 {
            folder = folders[indexPath.row]
        } else {
            folder = folders[indexPath.row + 2]
        }
        
        //셀에 표시하려는 폴더와 현재 폴더와 같으면 disable, 휴지통이면 disable
        cell.isDisable = (folder == self.folder || folder.isTrash)
        cell.folder = folder
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
        moveButton.isEnabled = true 
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        let folder: Folder
        if indexPath.section == 0 {
            folder = folders[indexPath.row]
        } else {
            folder = folders[indexPath.row + 2]
        }
        
        if folder == self.folder {
            return nil
        } else if folder.isTrash {
            return nil
        }
        return indexPath
    }
    
}
