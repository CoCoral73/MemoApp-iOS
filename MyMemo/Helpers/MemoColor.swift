//
//  MemoColor.swift
//  MyMemo
//
//  Created by 김정원 on 2/20/25.
//

import UIKit

enum MemoColor: Int64 {
    case pink = 1
    case yellow = 2
    case green = 3
    case blue = 4
    case purple = 5
    case base = 6
    
    var backgroundColor: UIColor {
        switch self {
        case .pink:
            return UIColor(red: 1.00, green: 0.71, blue: 0.76, alpha: 1.00)
        case .yellow:
            return UIColor(red: 1.00, green: 0.96, blue: 0.56, alpha: 1.00)
        case .green:
            return UIColor(red: 0.76, green: 0.88, blue: 0.76, alpha: 1.00)
        case .blue:
            return UIColor(red: 0.65, green: 0.78, blue: 0.91, alpha: 1.00)
        case .purple:
            return UIColor(red: 0.90, green: 0.90, blue: 0.98, alpha: 1.00)
        case .base: //FFFFF0
            return UIColor(red: 1.00, green: 1.00, blue: 0.94, alpha: 1.00)
        }
    }
    
    /*
    var navigationBarColor: UIColor {
        switch self {
        case .pink:
            return UIColor(red: 1.00, green: 0.66, blue: 0.71, alpha: 1.00)
        case .yellow:
            return UIColor(red: 1.00, green: 0.95, blue: 0.47, alpha: 1.00)
        case .green:
            return UIColor(red: 0.70, green: 0.85, blue: 0.70, alpha: 1.00)
        case .blue:
            return UIColor(red: 0.60, green: 0.75, blue: 0.88, alpha: 1.00)
        case .purple:
            return UIColor(red: 0.85, green: 0.83, blue: 0.94, alpha: 1.00)
        }
    }
     */
}
