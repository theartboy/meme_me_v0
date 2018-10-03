//
//  ViewController.swift
//  MemeMe
//
//  Created by John McCaffrey on 10/1/18.
//  Copyright © 2018 John McCaffrey. All rights reserved.
//

import UIKit

struct Meme {
    var topText: String
    var bottomText: String
    var originalImage: UIImage
    var memedImage: UIImage
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var topTextfield: UITextField!
    @IBOutlet weak var bottomTextfield: UITextField!
    
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    let memeTextDelegate = MemeTextFieldDelegate()
    var movementAllowed: Bool!
    
    let memeTextAttributes: [String: Any] = [
        NSAttributedStringKey.foregroundColor.rawValue: UIColor.white,
        NSAttributedStringKey.font.rawValue: UIFont(name: "Impact", size: 40)!,
        NSAttributedStringKey.strokeColor.rawValue: UIColor.black,
        NSAttributedStringKey.strokeWidth.rawValue: -3.0//neg. value allows for both stroke and fill
        
    ]
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        topTextfield.delegate = memeTextDelegate
        bottomTextfield.delegate = memeTextDelegate
        
        topTextfield.defaultTextAttributes = memeTextAttributes
        bottomTextfield.defaultTextAttributes = memeTextAttributes
        
        topTextfield.textAlignment = .center
        bottomTextfield.textAlignment = .center
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tapGesture.numberOfTapsRequired = 2
        
        imagePickerView.contentMode = .scaleAspectFit
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        subscribeToKeyboardNotifications()
        
        if (imagePickerView.image != nil) {
            resetNavElements(buttonsEnabled: true)
        } else {
            resetNavElements(buttonsEnabled: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func resetNavElements(buttonsEnabled: Bool){
        shareButton.isEnabled = buttonsEnabled
        cancelButton.isEnabled = buttonsEnabled
        movementAllowed = buttonsEnabled
        if !buttonsEnabled {
            topTextfield.text = "TOP"
            bottomTextfield.text = "BOTTOM"
            imagePickerView.image = nil
        }
    }
    
    //MARK: Image items
    @IBAction func pickImage(_ sender: UIBarButtonItem) {
        if imagePickerView.image != nil {
            imagePickerView.transform = CGAffineTransform.identity
        }
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        //tag property set for each button in IB
        switch sender.tag {
        case 0:
            print("library")
            imagePicker.sourceType = .photoLibrary
        case 1:
            print("camera")
            imagePicker.sourceType = .camera
        default:
            print("no item selected")
        }
        present(imagePicker,animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imagePickerView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func generateMemedImage() -> UIImage {
        //Hide toolbar and navbar
        toolBar.isHidden = true
        navigationController?.navigationBar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //Show toolbar and navbar
        toolBar.isHidden = false
        navigationController?.navigationBar.isHidden = false
        
        return memedImage
    }
    
    //MARK: Actions
    func save(newMeme: UIImage) {
        // Create the meme
        _ = Meme(topText: topTextfield.text!, bottomText: bottomTextfield.text!, originalImage: imagePickerView.image!, memedImage: newMeme)
    }
    
    @IBAction func shareMeme(_ sender: UIBarButtonItem) {
        let image = generateMemedImage()
        
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil);
        controller.completionWithItemsHandler = {
            (activity, success, items, error) in
            if(success && error == nil){
                print("completed \(activity as Any) \(success) \(items as Any) \(error as Any)")
                self.save(newMeme: image)
                self.dismiss(animated: true, completion: nil);
            }
            else if (error != nil){
                //log the error
                print("error \(error as Any)")
            }
        }
        present(controller, animated: true)
    }
    
    @IBAction func cancelMeme(_ sender: UIBarButtonItem) {
        resetNavElements(buttonsEnabled: false)
        imagePickerView.transform = CGAffineTransform.identity
    }
    
    //MARK: Image Gestures
    @IBAction func pinch(_ sender: UIPinchGestureRecognizer) {
        if movementAllowed {
            if let view = sender.view {
                view.transform = view.transform.scaledBy(x: sender.scale, y: sender.scale)
                sender.scale = 1
            }
        }
    }
    
    @IBAction func pan(_ sender:UIPanGestureRecognizer) {
        if movementAllowed {
            let translation = sender.translation(in: self.view)
            if let view = sender.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
            }
            sender.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    @IBAction func tap(_ sender:UITapGestureRecognizer) {
        if movementAllowed {
            if let view = sender.view {
                view.transform = CGAffineTransform.identity
                view.center = CGPoint(x:self.view.center.x, y:self.view.center.y)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if imagePickerView.image != nil {
            movementAllowed = true
        } else {
            movementAllowed = false
        }
    }
    
    //MARK: Keyboard items
    @objc func keyboardWillShow(_ notification:Notification){
        //verify it the bottom textfield before shifting keyboard
        if bottomTextfield.isFirstResponder {
            view.frame.origin.y = -getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification){
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification:Notification)-> CGFloat{
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications(){
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    //MARK: default memory warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
