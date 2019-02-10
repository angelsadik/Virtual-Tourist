//
//  DetailsViewController.swift
//  Virtual Tourist
//
//  Created by Malak Sadik on 03/02/2019.
//  Copyright © 2019 Malak Sadik. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var photo: Photo!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = UIImage(data: photo.image! as Data)
        titleLabel.text = photo.title
    }
    

}
