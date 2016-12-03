//
//  TaskHelper.swift
//  AgendaBuilder
//
//  Created by Adam Lagerhausen on 11/23/16.
//  Copyright © 2016 adam.lagerhausen. All rights reserved.
//

import Foundation

class TaskHelper: AnyObject {
    
    func stringToDate(string:String, tp:Bool) -> NSDate {
        
        let dateFormatter = DateFormatter()
        var date = NSDate()
        
        if tp == true {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.date(from: string)! as NSDate
            
        } else {
            //Monday, July 18, 2016 at 12:00:00 AM
            
            let stringArray = string.components(separatedBy: " at ")
            //let trimmedString = stringArray[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            
            let trimmedString = stringArray[0].trimmingCharacters(in: .whitespaces)
            
            dateFormatter.dateFormat = "EEEE, MMMM dd, yyyy"
            date = dateFormatter.date(from: trimmedString)! as NSDate
            
        }
        
        return date
        
    }

}
