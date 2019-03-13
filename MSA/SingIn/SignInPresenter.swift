//
//  SignInPresenter.swift
//  MSA
//
//  Created by Pavlo Kharambura on 2/20/18.
//  Copyright © 2018 easyapps.solutions. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class UserSignInPresenter {
    
    private let auth: AuthModule
    private weak var view: SignInViewProtocol?
    
    init(auth: AuthModule) {
        self.auth = auth
    }
    
    func attachView(view: SignInViewProtocol){
        self.view = view
    }
    
    func loginUserWithEmail(email: String, password: String) {
        AuthModule.facebookAuth = false
        self.view?.startLoading()
        auth.loginUser(email: email, pass: password) { (user, error) in
            self.view?.finishLoading()
            if error == nil && user != nil {
                let user = UserVO(id: user?.id, email: user?.email, firstName: user?.firstName, lastName: user?.lastName, avatar: user?.avatar, level: user?.level, age: user?.age, sex: user?.sex, height: user?.height, heightType: user?.heightType, weight: user?.weight,weightType: user?.weightType, type: user?.type, purpose: user?.purpose, gallery: user?.gallery, friends: user?.friends, trainerId: user?.trainerId, sportsmen: user?.sportsmen, requests: user?.requests, city: user?.city)
                    self.view?.setUser(user: user)
                    UserDataManager().getUser(callback: { (user, error) in
                        if let user = user {
                            self.view?.setUser(user: user)
                            self.view?.logged()
                            self.view?.finishLoading()
                        }
                    })
                    return
            } else {
                if error?.localizedDescription == AuthErrors.wrongPassword.rawValue {
                    self.view?.finishLoading()
                    self.view?.notLogged(resp: "Неверный формат пароль.")
                } else if error?.localizedDescription == AuthErrors.noRegistratedUser.rawValue {
                    self.view?.finishLoading()
                    self.view?.notLogged(resp: "Пользователь не зарегистрирован.")
                } else if error?.localizedDescription == AuthErrors.badEmailFormat.rawValue {
                    self.view?.finishLoading()
                    self.view?.notLogged(resp: "Неверный формат email.")
                } else {
                    self.view?.finishLoading()
                    self.view?.notLogged(resp: "Повторите позже.")
                }

//                if let error = error, let nsError = error as? NSError, let name = nsError.userInfo["error_name"] as? String {
//                    if name == "ERROR_USER_NOT_FOUND" {
//                        self.view?.notLogged(resp: "Юзер не найден")
//                    } else if name == "ERROR_USER_DISABLED" {
//                       self.view?.notLogged(resp: "Учетная запись пользователя отключена")
//                    }else if name == "ERROR_USER_TOKEN_EXPIRED" {
//                        self.view?.notLogged(resp: "Учетная запись пользователя отключена")
//                    }else if name == "ERROR_INVALID_USER_TOKEN" {
//                        self.view?.notLogged(resp: "Учетная запись пользователя отключена")
//                    }else if name == "ERROR_EMAIL_ALREADY_IN_USE" {
//                        self.view?.notLogged(resp: "Учетная запись пользователя отключена")
//                    }else if name == "ERROR_CREDENTIAL_ALREADY_IN_USE" {
//                        self.view?.notLogged(resp: "Учетная запись пользователя отключена")
//                    }
//                    if error.domain == "FIRAuthErrorCodeOperationNotAllowed" {
//                        self.view?.notLogged(resp: "Учетные записи электронной почты и пароли не включены")
//                    } else if error.domain == "FIRAuthErrorCodeInvalidEmail" {
//                        self.view?.notLogged(resp: "Адрес электронной почты неверный")
//                    } else if error.domain == "FIRAuthErrorCodeUserDisabled" {
//                        self.view?.notLogged(resp: "Учетная запись пользователя отключена")
//                    } else if error.domain == "FIRAuthErrorCodeWrongPassword" {
//                        self.view?.notLogged(resp: "Неверный пароль")
//                    } else {
//                        self.view?.notLogged(resp: "")
//                    }
//                }
            }
        }
    }
    
    func registerUser(email: String, password: String) {
        self.view?.startLoading()
        auth.registerUser(email: email, pass: password) { (user, error) in
            if error == nil && user != nil {
                let user = UserVO(id: user?.id, email: user?.email, firstName: AuthModule.currUser.firstName, lastName: AuthModule.currUser.lastName, avatar: nil, level: nil, age: nil, sex: nil, height: nil, heightType: nil, weight: nil,weightType: nil, type: AuthModule.currUser.type, purpose: user?.purpose, gallery: nil, friends: nil, trainerId: nil, sportsmen: nil, requests: nil, city: nil)
                self.view?.setUser(user: user)
                self.view?.registrated()
                self.view?.finishLoading()
            } else if error?.localizedDescription == AuthErrors.badEmailFormat.rawValue {
                self.view?.finishLoading()
                    self.view?.notRegistrated(resp: "Формат email неверный")
            } else if error?.localizedDescription == AuthErrors.userExist.rawValue {
                self.view?.finishLoading()
                    self.view?.notRegistrated(resp: "Пользователь с таким email уже зарегистрирован")
            } else if error?.localizedDescription == AuthErrors.shortPassword.rawValue {
                self.view?.finishLoading()
                    self.view?.notRegistrated(resp: "Пароль слишком короткий")
            } else {
                self.view?.finishLoading()
                    self.view?.notRegistrated(resp: "Ошибка регистрации")
            }
        }
    }
    
    func loginWithFacebook() {
        self.view?.startLoading()
        AuthModule.facebookAuth = true
        auth.loginFacebook { (user, error) in
            self.view?.finishLoading()
            if error == nil && user != nil {
                let user = UserVO(id: user?.id, email: user?.email, firstName: user?.firstName, lastName: user?.lastName, avatar: user?.avatar, level: nil, age: nil, sex: nil, height: nil, heightType: nil, weight: nil,weightType: nil, type: nil, purpose: nil, gallery: nil, friends: nil, trainerId: nil, sportsmen: nil, requests: nil, city: nil)
                self.view?.setUser(user: user)
                self.view?.loggedWithFacebook()
                return
            } else {
                if let error = error {
                    let error = error as NSError
                    if error.domain == "FIRAuthErrorCodeInvalidCredential" {
                        self.view?.notLogged(resp: "Предоставленные учетные данные недействительны")
                    } else if error.domain == "FIRAuthErrorCodeInvalidEmail" {
                        self.view?.notLogged(resp: "Адрес электронной почты искажен")
                    } else if error.domain == "FIRAuthErrorCodeOperationNotAllowed" {
                        self.view?.notLogged(resp: "Учетные записи с поставщиком удостоверений, представленным учетными данными, не включены")
                    } else if error.domain == "FIRAuthErrorCodeEmailAlreadyInUse" {
                        self.view?.notLogged(resp: "Электронная почта, указанная в учетных данных, уже используется существующей учетной записью")
                    } else if error.domain == "FIRAuthErrorCodeUserDisabled" {
                        self.view?.notLogged(resp: "Учетная запись пользователя отключена")
                    } else if error.domain == "FIRAuthErrorCodeWrongPassword" {
                        self.view?.notLogged(resp: "Неверный пароль")
                    } else {
                        self.view?.notLogged(resp: "Ошибка авторизации")
                    }
                }
            }
        }
    }
    
    func saveUser(context: NSManagedObjectContext, user: UserVO) {
        deleteUserBlock(context: context)
        let task = User(context: context)
        task.avatar = user.avatar
        task.id = user.id
        task.email = user.email
        task.name = user.firstName
        task.surname = user.lastName
        task.type = user.type
        task.level = user.level
        task.sex = user.sex
        task.heightType = user.heightType
        task.weightType = user.weightType
        task.purpose = user.purpose
        task.trainerId = user.trainerId
        if let age = user.age {
            task.age = Int64(age)
        }
        if let height = user.height {
            task.height = Int64(height)
        }
        if let weight = user.weight {
            task.weight = Int64(weight)
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func deleteUserBlock(context: NSManagedObjectContext) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            let _ = try context.execute(request)
        } catch {
            
        }
    }
    
    func fetchUser(context: NSManagedObjectContext)  {
        var loggedUser = UserVO()
        do {
            let user: [User] = try context.fetch(User.fetchRequest())
            loggedUser.id = user.first?.id
            loggedUser.avatar = user.first?.avatar
            loggedUser.email = user.first?.email
            loggedUser.firstName = user.first?.name
            loggedUser.lastName = user.first?.surname
            loggedUser.level = user.first?.level
            loggedUser.type = user.first?.type
            loggedUser.sex = user.first?.sex
            loggedUser.weightType = user.first?.weightType
            loggedUser.heightType = user.first?.heightType
            loggedUser.avatar = user.first?.avatar
            loggedUser.purpose = user.first?.purpose
            loggedUser.trainerId = user.first?.trainerId

            if let age = user.first?.age {
                loggedUser.age = Int(age)
            }
            if let height = user.first?.height {
                loggedUser.height = Int(height)
            }
            if let weight = user.first?.weight {
                loggedUser.weight = Int(weight)
            }
            if let _ = loggedUser.id {
                AuthModule.currUser = loggedUser
            }
            if let _ = AuthModule.currUser.id {
                self.view?.logged()
            }
        } catch {
            print("Fetching Failed")
        }
    }

    func setUser(user: UserVO, context: NSManagedObjectContext) {
        AuthModule.currUser = user
        if let gallery = AuthModule.currUser.gallery {
            GalleryDataManager.GalleryItems = gallery
        }
        saveUser(context: context, user: user)
    }
    func setNoUser() {
        AuthModule.currUser = UserVO()
    }
}
