//
//  CoreDataManager.swift
//  MyMemo
//
//  Created by 김정원 on 2/18/25.
//

import UIKit
import CoreData

final class CoreDataManager {
    
    //싱글톤 패턴
    static let shared = CoreDataManager()
    private init() {}
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    lazy var context = appDelegate?.persistentContainer.viewContext
    
    private var trashFolder: Folder?
    
    let folderModelName: String = "Folder"
    let memoModelName: String = "Memo"
    
    //MARK: 폴더 관리
    func seedInitialDataIfNeeded() {
        if let context = context {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            
            do {
                let count = try context.count(for: request)
                if count == 0 {
                    // 예시: 기본 폴더와 메모 생성
                    let defaultFolder = Folder(context: context)
                    defaultFolder.name = "기본 폴더"
                    defaultFolder.date = Date()
                    defaultFolder.isTrash = false
                    
                    let trashFolder = Folder(context: context)
                    trashFolder.name = "휴지통"
                    trashFolder.date = Date()
                    trashFolder.imageName = "trash"
                    trashFolder.isTrash = true
                    
                    try context.save()
                    print("초기 데이터 생성 완료")
                }
            } catch {
                print("초기 데이터 생성 에러: \(error.localizedDescription)")
            }
        }
    }
    
    func getFolderListFromCoreData() -> [Folder] {
        var folderList: [Folder] = []
        if let context = context {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
                    
            do {
                folderList = try context.fetch(request)
                print("폴더 fetch 성공")
            } catch {
                print("폴더 fetch 에러: \(error.localizedDescription)")
            }
        }
        return folderList
    }
    
    func getOrCreateTrashFolder() -> Folder? {
        if let trashFolder = trashFolder {
            return trashFolder
        }
        
        if let context = context {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.predicate = NSPredicate(format: "isTrash == true")
            
            do {
                let results = try context.fetch(request)
                if let folder = results.first {
                    trashFolder = folder
                    return folder
                }
            } catch {
                print("휴지통 폴더 fetch 에러: \(error)")
            }
        }
        return nil
    }
    
    func addFolder(name: String?, completionHandler: @escaping () -> Void) {
        if let context = context {
            if let entity = NSEntityDescription.entity(forEntityName: self.folderModelName, in: context) {
                if let folder = NSManagedObject(entity: entity, insertInto: context) as? Folder {
                    folder.name = name
                    folder.date = Date()
                    folder.isTrash = false
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        
        completionHandler()
    }
    
    func updateFolderName(newName: String?, completionHandler: @escaping () -> Void) {
        //폴더명 수정
        
    }
    
    func deleteFolder(folder: Folder, completionHandler: @escaping () -> Void) {
        guard let date = folder.date else {
            completionHandler()
            return
        }
        guard let trashFolder = getOrCreateTrashFolder() else { return }
        
        if let context = context {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
            
            do {
                let fetchedList = try context.fetch(request)
                if let targetFolder = fetchedList.first {
                    if let memosSet = targetFolder.memos as? Set<Memo> {
                        memosSet.sorted { return ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }.forEach { memo in
                            memo.folder = trashFolder
                            memo.deletedDate = Date()
                        }
                    }
                    
                    context.delete(targetFolder)
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            completionHandler()
        }
    }
    
    //MARK: 메모 관리
    func getMemoListFromCoreData(selectedFolder: Folder) -> [Memo] {
        var memoList: [Memo] = []
        
        if let context = context {
            let request: NSFetchRequest<Memo> = Memo.fetchRequest()
            request.predicate = NSPredicate(format: "folder = %@", selectedFolder as CVarArg)
            
            if selectedFolder.isTrash {
                request.sortDescriptors = [NSSortDescriptor(key: "deletedDate", ascending: false)]
            } else {
                request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            }
            
            do {
                memoList = try context.fetch(request)
            } catch {
                print("메모 fetch 에러: \(error.localizedDescription)")
            }
        }
        return memoList
    }
    
    func addMemo(text: String?, color: Int64, folder: Folder, date: Date?, completionHandler: @escaping () -> Void) {
        if let context = context {
            if let entity = NSEntityDescription.entity(forEntityName: self.memoModelName, in: context) {
                if let memo = NSManagedObject(entity: entity, insertInto: context) as? Memo {
                    memo.text = text
                    memo.color = color
                    memo.date = date
                    memo.folder = folder
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        completionHandler()
    }
    
    func updateMemo(memo: Memo, completionHandler: @escaping () -> Void) {
        guard let date = memo.date else {
            completionHandler()
            return
        }
        
        if let context = context {
            let request: NSFetchRequest<Memo> = Memo.fetchRequest()
            request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
            
            do {
                let fetchedList = try context.fetch(request)
                if var targetMemo = fetchedList.first {
                    targetMemo = memo
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            completionHandler()
        }
    }
    
    func deleteMemo(memo: Memo, completionHandler: @escaping () -> Void) {
        guard let date = memo.date else {
            completionHandler()
            return
        }
        guard let trashFolder = getOrCreateTrashFolder() else { return }

        if let context = context {
            let request: NSFetchRequest<Memo> = Memo.fetchRequest()
            request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
            
            do {
                let fetchedList = try context.fetch(request)
                if let targetMemo = fetchedList.first {
                    targetMemo.folder = trashFolder
                    targetMemo.deletedDate = Date()
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            completionHandler()
        }
    }
    
    func deleteEmptyMemo(memo: Memo, completionHandler: @escaping () -> Void) {
        guard let date = memo.date else {
            completionHandler()
            return
        }

        if let context = context {
            let request: NSFetchRequest<Memo> = Memo.fetchRequest()
            request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
            
            do {
                let fetchedList = try context.fetch(request)
                if let targetMemo = fetchedList.first {
                    context.delete(targetMemo)
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            completionHandler()
        }
    }
    
    func deleteAllMemoFromFolder(folder: Folder, completionHandler: @escaping () -> Void) {
        guard let date = folder.date else {
            completionHandler()
            return
        }
        guard let trashFolder = getOrCreateTrashFolder() else { return }
        
        if let context = context {
            let request: NSFetchRequest<Folder> = Folder.fetchRequest()
            request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
            
            do {
                let fetchedList = try context.fetch(request)
                if let targetFolder = fetchedList.first {
                    if let memosSet = targetFolder.memos as? Set<Memo> {
                        memosSet.sorted { return ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }.forEach { memo in
                            memo.folder = trashFolder
                            memo.deletedDate = Date()
                        }
                    }
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            completionHandler()
        }
    }
    
    func deleteMemoFromTrash(memo: Memo, completionHandler: @escaping () -> Void) {
        guard let date = memo.date else {
            completionHandler()
            return
        }
        
        if let context = context {
            let request: NSFetchRequest<Memo> = Memo.fetchRequest()
            request.predicate = NSPredicate(format: "date = %@", date as CVarArg)
            
            do {
                let fetchedList = try context.fetch(request)
                if let targetMemo = fetchedList.first {
                    context.delete(targetMemo)
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            completionHandler()
        }
    }
    
    func deleteAllMemoFromTrash(completionHandler: @escaping () -> Void) {
        guard let trashFolder = getOrCreateTrashFolder() else {
            completionHandler()
            return
        }
        
        if let context = context {
            if let memosSet = trashFolder.memos as? Set<Memo> {
                do {
                    for memo in memosSet {
                        context.delete(memo)
                    }
                    try context.save()
                } catch {
                    print("휴지통 비우기 에러: \(error.localizedDescription)")
                }
            }
        }
        completionHandler()
    }
    
    func deleteOldMemoFromTrash() {
        guard let before30days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else { return }
        
        if let context = context {
            let request: NSFetchRequest<Memo> = Memo.fetchRequest()
            // 휴지통에 있고, deletedDate가 thresholdDate보다 이전인 메모를 찾음
            request.predicate = NSPredicate(format: "folder.isTrash == true AND deletedDate <= %@", before30days as NSDate)
            
            do {
                let oldTrashMemos = try context.fetch(request)
                for memo in oldTrashMemos {
                    context.delete(memo)
                }
                try context.save()
                print("오래된 휴지통 메모 \(oldTrashMemos.count)개 삭제 완료")
            } catch {
                print("휴지통 메모 삭제 에러: \(error.localizedDescription)")
            }
        }
    }
}
