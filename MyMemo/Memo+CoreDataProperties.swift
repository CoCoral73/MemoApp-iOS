//
//  Memo+CoreDataProperties.swift
//  MyMemo
//
//  Created by 김정원 on 2/20/25.
//
//

import Foundation
import CoreData


extension Memo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Memo> {
        return NSFetchRequest<Memo>(entityName: "Memo")
    }

    @NSManaged public var text: String?
    @NSManaged public var date: Date?
    @NSManaged public var deletedDate: Date?
    @NSManaged public var color: Int64
    @NSManaged public var password: Int64
    @NSManaged public var folder: Folder

    var dateString: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "생성 일자: yyyy년 M월 d일 a h:mm"
        guard let date = self.date else { return "" }
        return formatter.string(from: date)
    }
    
    var deletedDateString: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "삭제 일자: yyyy년 M월 d일"
        guard let deletedDate = self.deletedDate else { return "" }
        return formatter.string(from: deletedDate)
    }
}

extension Memo : Identifiable {

}
