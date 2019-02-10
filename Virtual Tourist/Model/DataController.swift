//
//  TouristDataController.swift
//  Virtual Tourist
//
//  Created by Malak Sadik on 24/01/2019.
//  Copyright © 2019 Malak Sadik. All rights reserved.
//

import Foundation
import CoreData

class DataController {// 1. add a controller property at the AppDelegate so persistentData is loaded as soon the app launches

    static let shared = DataController(modelName: "Virtual_Tourist")
    
    let persistentContainer:NSPersistentContainer //to help load the persistance storag and access the context

    var viewContext:NSManagedObjectContext { // a computed property
        return persistentContainer.viewContext
}

init(modelName:String) {//initializer: passing the name of the data model file name
    persistentContainer = NSPersistentContainer(name: modelName)
    
}

func load(completion: (() -> Void)? = nil) { // load the persistance store
    //loadPersistentStrore accepts a completion handlers as a parameter
    persistentContainer.loadPersistentStores { storeDescription, error in// a completion closure
        guard error == nil else {
            fatalError(error!.localizedDescription) //if error stop execution and log the problem
        }
        //after loading the store
        self.autoSaveViewContext()
        //self.configureContexts()
        completion?() //the function parameter of type closure which is optional and defaulted to nil in the function def
    }
}
}

// MARK: - Autosaving

extension DataController {
    //auto saving every 30 sec
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        
        guard interval > 0 else { //time should be positive
            print("cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges { // every 30 check if changes then save
            try? viewContext.save()
        }
        //call again after interval elapsed
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}

