//
//  ImageViewController.swift
//  SearchShindig
//
//  Created by Heather Shelley on 3/10/15.
//  Copyright (c) 2015 Mine. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var urlString: String = ""
    
    override func viewDidLoad() {
        if let url = NSURL(string: urlString) {
            imageView.setImageWithURL(url)
        }
    }

}
