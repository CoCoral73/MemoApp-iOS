//
//  Folder+CoreDataProperties.swift
//  MyMemo
//
//  Created by 김정원 on 2/20/25.
//
//

import Foundation
import CoreData


extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var isTrash: Bool
    @NSManaged public var imageName: String?
    @NSManaged public var name: String?
    @NSManaged public var date: Date?
    @NSManaged public var memos: NSSet?

}

// MARK: Generated accessors for memos
extension Folder {

    @objc(addMemosObject:)
    @NSManaged public func addToMemos(_ value: Memo)

    @objc(removeMemosObject:)
    @NSManaged public func removeFromMemos(_ value: Memo)

    @objc(addMemos:)
    @NSManaged public func addToMemos(_ values: NSSet)

    @objc(removeMemos:)
    @NSManaged public func removeFromMemos(_ values: NSSet)

}

extension Folder : Identifiable {

}
