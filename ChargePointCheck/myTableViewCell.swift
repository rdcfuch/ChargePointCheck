//
//  myTableViewCell.swift
//  ChargePointCheck
//
//  Created by Chen Fu on 6/10/17.
//  Copyright © 2017 Chen Fu. All rights reserved.
//

import UIKit

class myTableViewCell: UITableViewCell {

    @IBOutlet weak var buildingNum: UILabel!
    @IBOutlet weak var stationNum: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var availablePortNumLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
