//
//  DataBase.swift
//  YTS
//
//  Created by Igor Voynov on 29.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import RealmSwift

class DataBase {
    
    let realm = try! Realm()
    
    func executeInTransaction(execute: (() -> Void) ) {
        realm.beginWrite()
        execute()
        do {
            try realm.commitWrite()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func updateInTransaction(object: Object) {
        realm.add(object, update: true)
    }
 
    func write(object: Object) {
        do {
            try realm.write {
                realm.add(object)
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func update(object: Object) {
        do {
            try realm.write {
                realm.add(object, update: true)
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func deleteAll() {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func getObjects<T: Object>(type: T.Type, query: String? = nil) -> Results<T> {
        if query != nil {
            return realm.objects(type).filter(query!)
        } else {
            return realm.objects(type)
        }
    }
    
}
