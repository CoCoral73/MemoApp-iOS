//
//  Constants.swift
//  MyMemo
//
//  Created by 김정원 on 2/18/25.
//

import Foundation

public struct Cell {
    static let folderCellIdentifier = "FolderCell"
    static let moveFolderCellIdentifier = "MoveFolderCell"
    static let memoCellIdentifier = "MemoCell"
    
    private init() {}
}

public struct Segue {
    static let folderToMemoIdentifier = "FolderToMemo"
    static let memoToDetailIdentifier = "MemoToDetail"
    static let moveMemoInMemoViewIdentifier = "MoveInMemoView"
    static let moveMemoInDetailViewIdentifier = "MoveInDetailView"
    static let lockMemoIdentifier = "LockMemo"
    
    private init() {}
}
