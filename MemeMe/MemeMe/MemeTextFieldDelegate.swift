//
//  MemeTextFieldDelegate.swift
//  MemeMe
//
//  Created by John McCaffrey on 10/2/18.
//  Copyright © 2018 John McCaffrey. All rights reserved.
//

import Foundation
import UIKit



class MemeTextFieldDelegate: NSObject, UITextFieldDelegate {
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true;
    }
}

