//
//  FolderCell.swift
//  MyMemo
//
//  Created by 김정원 on 2/18/25.
//

import UIKit

class FolderCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var editMode: Bool = false
    var folder: Folder? {
        didSet {
            configureUI(editMode)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.iconImageView.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureUI(_ editing: Bool) {
        
        guard let folder = self.folder else { return }
        let memos = folder.memos
        
        iconImageView.image = UIImage(systemName: folder.imageName ?? "folder")
        titleLabel.text = folder.name
        subtitleLabel.text = "\(memos == nil ? 0 : memos!.count)"
        subtitleLabel.textColor = .darkGray
        
        if editing {
            if self.folder?.name == "기본 폴더" || self.folder?.name == "휴지통" {
                self.iconImageView.tintColor = UIColor.gray
                self.titleLabel.textColor = UIColor.gray
            } else {
                self.iconImageView.tintColor = .systemOrange
                self.titleLabel.textColor = .label
            }
            self.subtitleLabel.isHidden = editing
            self.accessoryType = .none
        } else {
            self.iconImageView.tintColor = .systemOrange // 또는 원래 색상
            self.titleLabel.textColor = UIColor.label
            self.subtitleLabel.isHidden = editing
            self.accessoryType = .disclosureIndicator
        }
        
    }

}
