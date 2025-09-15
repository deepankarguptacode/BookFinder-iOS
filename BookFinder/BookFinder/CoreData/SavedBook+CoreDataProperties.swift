//
//  SavedBook+CoreDataProperties.swift
//  BookFinder
//
//  Created by Deepankar Gupta on 15/09/25.
//
//

import Foundation
import CoreData


extension SavedBook {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedBook> {
        return NSFetchRequest<SavedBook>(entityName: "SavedBook")
    }

    @NSManaged public var author: String?
    @NSManaged public var bookDescription: String?
    @NSManaged public var coverURL: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: String?
    @NSManaged public var publishYear: Int64
    @NSManaged public var title: String?

}

extension SavedBook : Identifiable {

}
