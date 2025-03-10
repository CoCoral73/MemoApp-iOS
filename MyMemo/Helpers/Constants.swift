//
//  Constants.swift
//  MyMemo
//
//  Created by 김정원 on 2/18/25.
//

import Foundation

public struct Cell {
    static let folderCellIdentifier = "FolderCell"  //폴더뷰에서, 테이블뷰 셀
    static let moveFolderCellIdentifier = "MoveFolderCell"  //메모이동뷰에서, 테이블뷰 셀
    static let memoCellIdentifier = "MemoCell"  //메모뷰에서, 테이블뷰 셀
    
    private init() {}
}

public struct Segue {
    static let folderToMemoIdentifier = "FolderToMemo"  //폴더뷰 -> 메모뷰
    static let memoToDetailIdentifier = "MemoToDetail"  //메모뷰 -> 디테일뷰
    static let moveMemoInMemoViewIdentifier = "MoveInMemoView"  //메모뷰 -> 메모이동뷰
    static let moveMemoInDetailViewIdentifier = "MoveInDetailView"  //디테일뷰 -> 메모이동뷰
    static let lockMemoIdentifier = "LockMemo"  //디테일뷰 -> 메모잠금뷰
    
    private init() {}
}
