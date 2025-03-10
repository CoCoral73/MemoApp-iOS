//
//  MoveFolderCell.swift
//  MyMemo
//
//  Created by 김정원 on 2/24/25.
//

import UIKit

class MoveFolderCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var isDisable: Bool?
    var folder: Folder? {
        didSet {
            configureUIwithData()
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
    
    func configureUIwithData() {
        guard let isDisable = self.isDisable else { return }
        guard let folder = self.folder else { return }
        iconImageView.image = UIImage(systemName: folder.imageName ?? "folder")
        titleLabel.text = folder.name
        
        if isDisable {
            iconImageView.tintColor = .gray
            titleLabel.textColor = .gray
        } else {
            iconImageView.tintColor = .systemOrange
            titleLabel.textColor = .label
        }
    }

}
