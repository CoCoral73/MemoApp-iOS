//
//  MemoCell.swift
//  MyMemo
//
//  Created by 김정원 on 2/20/25.
//

import UIKit

class MemoCell: UITableViewCell {

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var memoTextLabel: UILabel!
    
    var memo: Memo? {
        didSet {
            configureUIwithData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configureUI()
    }
    
    func configureUI() {
        backView.clipsToBounds = true
        backView.layer.cornerRadius = 8
        self.backgroundColor = MemoColor.base.backgroundColor
    }
    
    func configureUIwithData() {
        if let memo = self.memo, let _ = memo.password {
            memoTextLabel.text = memo.text?.components(separatedBy: ["\n"]).first
        } else {
            memoTextLabel.text = memo?.text
        }
        
        guard let colorNum = memo?.color else { return }
        let color = MemoColor(rawValue: colorNum) ?? .pink
        backView.backgroundColor = color.backgroundColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
