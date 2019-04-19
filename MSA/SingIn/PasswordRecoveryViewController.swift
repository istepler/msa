//
//  PasswordRecoveryViewController.swift
//  MSA
//
//  Created by Pavlo Kharambura on 4/19/19.
//  Copyright © 2019 Pavlo Kharambura. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class PasswordRecoveryViewController: UIViewController {

    @IBOutlet weak var textField: SkyFloatingLabelTextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.stopAnimating()
        self.view.isUserInteractionEnabled = true
    }
    
    @IBAction func recoverPassword(_ sender: Any) {
        if let email = textField.text, email.isValidEmail {
            activityIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
            AuthModule.sendRecoverPasswordRequest(email: email) { (error) in
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                DispatchQueue.main.async {
                    if error == nil {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        if error?.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted." {
                            AlertDialog.showAlert("Ошибка", message: "Нету пользователя с такой почтой", viewController: self)
                        } else {
                            AlertDialog.showAlert("Ошибка", message: error?.localizedDescription ?? "Повторите позже", viewController: self)
                        }
                    }
                }
            }
        } else {
            AlertDialog.showAlert("Ошибка", message: "Введите валидную почту", viewController: self)
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
