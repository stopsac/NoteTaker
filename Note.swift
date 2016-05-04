//
//  Note.swift
//  NoteTaker
//
//  Created by Bono Kim on 4/6/16.
//  Copyright © 2016 Engene. All rights reserved.
//

import Foundation
import CoreData


class Note: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    @NSManaged var url: String?
    @NSManaged var name: String?


}
