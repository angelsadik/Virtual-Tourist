//
//  Extension.swift
//  Virtual Tourist
//
//  Created by Malak Sadik on 03/02/2019.
//  Copyright © 2019 Malak Sadik. All rights reserved.
//

import Foundation

import UIKit

extension UIViewController {
    // show alert message
    func showAlertMessage(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let alertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alertController.addAction(alertAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

