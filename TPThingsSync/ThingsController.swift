//
//  ViewController.swift
//  TaskpaperSerializer
//
//  Created by Adam Lagerhausen on 7/15/16.
//  Copyright © 2016 adam.lagerhausen. All rights reserved.
//

import Cocoa
import BirchOutline


class ThingsController: AnyObject {

    struct ThingsTask {
        var name: String
        var dueDate: String
        var comDate: String
    }
    
    public enum dateType {
        case Today
        case Tomorrow
        case Week
        case Month
        case Future
    }
    
    func getOutline() -> String {
        let ud = UserDefaults.standard
        let path = ud.string(forKey: "filePath")
        
        let location = NSString(string:path!).expandingTildeInPath
        let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
        
        return fileContent as! String
        
    }

    func sync() {
        
        let outline = BirchOutline.createTaskPaperOutline(self.getOutline())
        
        var tpItemsDueArray = [ItemType]()
        var tpItemsStartArray = [ItemType]()
        var tpItemsTodayArray = [ItemType]()
        var tpItemsDoneArray = [ItemType]()

        //Get all items with due dates
        let items = outline.items
        for item: ItemType in items {
            if item.hasAttribute("data-due") {
                if item.hasAttribute("data-done") {
                    //do nothing
                } else {
                    tpItemsDueArray.append(item)
                }
            }
        }
        
        //Get all items with start dates
        for item: ItemType in items {
            if item.hasAttribute("data-start") {
                if item.hasAttribute("data-done") {
                    //do nothing
                } else {
                    tpItemsStartArray.append(item)
                }
            }
        }

        //Get all items with Today
        for item: ItemType in items {
            if item.hasAttribute("data-today") {
                if item.hasAttribute("data-done") {
                    //do nothing
                } else {
                    tpItemsTodayArray.append(item)
                }
            }
        }

        //Get items from Things
        let appleScriptCode = "tell application \"Things\" \n repeat with toDo in to dos of area \"Taskpaper\" \n return name of toDo \n end repeat\n end tell"
        
        let script = NSAppleScript(source: appleScriptCode)
        var err : NSDictionary? = nil
        
        var toDoNames = ""
        var toDoDueDates = ""
        var toDoComDates = ""
        
        //Get things names
        let myAppleScriptNames = "tell application \"Things\" \n set myList to {} \n repeat with inboxToDo in to dos of area \"Taskpaper\" \n set myList to myList & {name of inboxToDo} \n end repeat \n try \n set AppleScript's text item delimiters to \";;\" \n set list_2_string to myList as text \n return list_2_string \n end try \n end tell \n"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScriptNames) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error) {
                //print(output.stringValue)
                
                toDoNames = output.stringValue!
                
            } else if (error != nil) {
                print("error: \(error)")
            }
        }
        
        //Get things due dates
        let myAppleScriptDueDates = "tell application \"Things\" \n set myList to {} \n repeat with inboxToDo in to dos of area \"Taskpaper\" \n set myList to myList & {due date of inboxToDo} \n end repeat \n try \n set AppleScript's text item delimiters to \";;\" \n set list_2_string to myList as text \n return list_2_string \n end try \n end tell \n"
        var error2: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScriptDueDates) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error2) {
                //print(output.stringValue)
                
                toDoDueDates = output.stringValue!
                
            } else if (error != nil) {
                print("error: \(error)")
            }
        }
        
        //Get things com dates
        let myAppleScriptComDates = "tell application \"Things\" \n set myList to {} \n repeat with inboxToDo in to dos of area \"Taskpaper\" \n set myList to myList & {completion date of inboxToDo} \n end repeat \n try \n set AppleScript's text item delimiters to \";;\" \n set list_2_string to myList as text \n return list_2_string \n end try \n end tell \n"
        var error3: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScriptComDates) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error3) {
                //print(output.stringValue)
                
                toDoComDates = output.stringValue!
                
            } else if (error != nil) {
                print("error: \(error)")
            }
        }
        
        let partsName = toDoNames.components(separatedBy: ";;")
        let partsDueDates = toDoDueDates.components(separatedBy: ";;")
        let partsComDates = toDoComDates.components(separatedBy: ";;")
        
        //print(partsComDates)
        
        //Array of task names and Due Dates
        //print(partsName)
        //print(partsDueDates)
        
        //Create dictionary of things tasks
        var thingsItemArray = [ThingsTask]()
        
        var i = 0
        for taskName in partsName {
            let thingToDo = ThingsTask(name: taskName, dueDate: partsDueDates[i], comDate: partsComDates[i])
            thingsItemArray.append(thingToDo)
            i += 1
            
        }
        
        //print(thingsItemArray)
        //print(tpItemsArray)
        
        //DUE: Find matching things tasks and taskpaper tasks
        for tpToDo in tpItemsDueArray {
            for thingsToDo in thingsItemArray {
                
                let bodyContent = removeTags(text: tpToDo.body)
                
                if thingsToDo.name == bodyContent {
                    
                    print(thingsToDo.name)
                    print(bodyContent)
                    
                    //Mark as completed if complete
                    if thingsToDo.comDate != "missing value" {
                        let comDate = stringToDate(string: thingsToDo.comDate, tp: false)
                        let comDateString = dateToString(date: comDate)
                        
                        tpToDo.setAttribute("data-done", value: comDateString)
                        
                        self.updateFileWithUpdates(outline: outline)
                    } else {
                        
                        //Find if date is different
                        let tpDueDate = (tpToDo.attributes["data-due"]! as String)
                        let tpDate = stringToDate(string: tpDueDate, tp: true)
                        
                        let thingsDate = stringToDate(string: thingsToDo.dueDate, tp: false)
                        
                        print(tpDate)
                        print(thingsDate)
                        
                        if tpDate == thingsDate {
                            print("Matching dates")
                        } else {
                            print("Non Matching dates")

                            //Change the date of the THINGS Task
                            let appleSriptCodeChangeThingsDueDate = "to convertDate(textDate) \n set resultDate to the current date \n set the year of resultDate to (text 1 thru 4 of textDate) \n set the month of resultDate to (text 6 thru 7 of textDate) \n set the day of resultDate to (text 9 thru 10 of textDate) \n set the time of resultDate to 0 \n if (length of textDate) > 10 then \n set the hours of resultDate to (text 12 thru 13 of textDate) \n set the minutes of resultDate to (text 15 thru 16 of textDate) \n end if \n return resultDate \n end convertDate \n tell application \"Things\" \n set toDo to to do named \"\(thingsToDo.name)\" \n set dateString to \"\(tpDueDate)\" \n set remDateFormatted to my convertDate(dateString) \n set due date of toDo to (remDateFormatted) \n end tell"
                            runAppleScript(script: appleSriptCodeChangeThingsDueDate)
                        }
                    }
                }
            }
        }
        
        //START: Find matching things tasks and taskpaper tasks
        for tpToDo in tpItemsStartArray {
            for thingsToDo in thingsItemArray {
                
                let bodyContent = removeTags(text: tpToDo.body)
                
                if thingsToDo.name == bodyContent {
                    
                    print(thingsToDo.name)
                    print(bodyContent)
                    
                    //Mark as completed if complete
                    if thingsToDo.comDate != "missing value" {
                        let comDate = stringToDate(string: thingsToDo.comDate, tp: false)
                        let comDateString = dateToString(date: comDate)
                        
                        tpToDo.setAttribute("data-done", value: comDateString)
                        
                        self.updateFileWithUpdates(outline: outline)
                    } else {
                        
                        //Set Scheduled
                        //Find if date today or in past
                        //if today or past, move to today list
                        let today = self.getDateType(item: tpToDo, due: false)
                        if today == .Today {
                            //set to today list
                            let appleSriptCodeChangeThingsToday = "tell application \"Things\" \n set toDo to to do named \"\(thingsToDo.name)\" \n move toDo to list \"Today\" \n end tell"
                            runAppleScript(script: appleSriptCodeChangeThingsToday)

                        } else {
                            //in furture, schedule
                            let tpStartDate = (tpToDo.attributes["data-start"]! as String)
                            
                            let appleSriptCodeChangeThingsStartDate = "to convertDate(textDate) \n set resultDate to the current date \n set the year of resultDate to (text 1 thru 4 of textDate) \n set the month of resultDate to (text 6 thru 7 of textDate) \n set the day of resultDate to (text 9 thru 10 of textDate) \n set the time of resultDate to 0 \n if (length of textDate) > 10 then \n set the hours of resultDate to (text 12 thru 13 of textDate) \n set the minutes of resultDate to (text 15 thru 16 of textDate) \n end if \n return resultDate \n end convertDate \n tell application \"Things\" \n set toDo to to do named \"\(thingsToDo.name)\" \n set dateString to \"\(tpStartDate)\" \n set remDateFormatted to my convertDate(dateString) \n schedule toDo for (remDateFormatted) \n end tell"
                            runAppleScript(script: appleSriptCodeChangeThingsStartDate)
                        }
                        
                        
                    }
                }
            }
        }
        
        //TODAY: Find matching things tasks and taskpaper tasks
        for tpToDo in tpItemsTodayArray {
            for thingsToDo in thingsItemArray {
                
                let bodyContent = removeTags(text: tpToDo.body)
                
                if thingsToDo.name == bodyContent {
                    
                    print(thingsToDo.name)
                    print(bodyContent)
                    
                    //Mark as completed if complete
                    if thingsToDo.comDate != "missing value" {
                        let comDate = stringToDate(string: thingsToDo.comDate, tp: false)
                        let comDateString = dateToString(date: comDate)
                        
                        tpToDo.setAttribute("data-done", value: comDateString)
                        
                        self.updateFileWithUpdates(outline: outline)
                    } else {
                        
                        //Set Today
                        let appleSriptCodeChangeThingsToday = "tell application \"Things\" \n set toDo to to do named \"\(thingsToDo.name)\" \n move toDo to list \"Today\" \n end tell"
                        runAppleScript(script: appleSriptCodeChangeThingsToday)
                    }
                }
            }
        }

        //DUE: Add new tpTasks to Things
        for tpToDo in tpItemsDueArray {
            let bodyContent = removeTags(text: tpToDo.body)
            if partsName.contains(bodyContent) {
                print("Matching")
                print(bodyContent)
            } else {
                print("Create new Task in Things")
                print(bodyContent)
                
                let tpDueDate = (tpToDo.attributes["data-due"]! as String)
                let tpDate = stringToDate(string: tpDueDate, tp: true)
                let myAppleScriptCreateNewThingsTask = String(format: "to convertDate(textDate)\n set resultDate to the current date \n set the year of resultDate to (text 1 thru 4 of textDate) \n set the month of resultDate to (text 6 thru 7 of textDate) \n set the day of resultDate to (text 9 thru 10 of textDate) \n set the time of resultDate to 0 \n if (length of textDate) > 10 then \n set the hours of resultDate to (text 12 thru 13 of textDate) \n set the minutes of resultDate to (text 15 thru 16 of textDate) \n end if \n return resultDate \n end convertDate \n tell application \"Things\" \n tell area \"Taskpaper\" \n set dateString to \"%@\" \n set remDateFormatted to my convertDate(dateString) \n set newToDo to make new to do ¬ \n with properties {name:\"%@\", due date:remDateFormatted} \n end tell \n end tell",tpDate , bodyContent)
                runAppleScript(script: myAppleScriptCreateNewThingsTask)
            }
        }
        
        //START: Add new tpTasks to Things
        for tpToDo in tpItemsStartArray {
            let bodyContent = removeTags(text: tpToDo.body)
            if partsName.contains(bodyContent) {
                print("Matching")
                print(bodyContent)
            } else {
                let tpStartDate = (tpToDo.attributes["data-start"]! as String)
                let tpDate = stringToDate(string: tpStartDate, tp: true)

                if tpToDo.hasAttribute("data-due") {
                    //just schedule
                    let appleSriptCodeChangeThingsStartDate = scheduleThingScript(name: bodyContent, date: tpDate)
                    runAppleScript(script: appleSriptCodeChangeThingsStartDate)

                } else {
                    print("Create new Task in Things")
                    print(bodyContent)
                    
                    let myAppleScriptCreateNewThingsTask = "to convertDate(textDate)\n set resultDate to the current date \n set the year of resultDate to (text 1 thru 4 of textDate) \n set the month of resultDate to (text 6 thru 7 of textDate) \n set the day of resultDate to (text 9 thru 10 of textDate) \n set the time of resultDate to 0 \n if (length of textDate) > 10 then \n set the hours of resultDate to (text 12 thru 13 of textDate) \n set the minutes of resultDate to (text 15 thru 16 of textDate) \n end if \n return resultDate \n end convertDate \n tell application \"Things\" \n tell area \"Taskpaper\" \n set dateString to \"\(tpStartDate)\" \n set remDateFormatted to my convertDate(dateString) \n set newToDo to make new to do ¬ \n with properties {name:\"\(bodyContent)\"} \n schedule newToDo for (remDateFormatted) \n end tell \n end tell"
                    runAppleScript(script: myAppleScriptCreateNewThingsTask)
                }
            }
        }

        //TODAY: Add new tpTasks to Things
        for tpToDo in tpItemsTodayArray {
            let bodyContent = removeTags(text: tpToDo.body)
            if partsName.contains(bodyContent) {
                print("Matching")
                print(bodyContent)
            } else {
                
                if tpToDo.hasAttribute("data-due") || tpToDo.hasAttribute("data-start") {
                    //just move to today
                    let appleSriptCodeChangeThingsToday = "tell application \"Things\" \n set toDo to to do named \"\(bodyContent)\" \n move toDo to list \"Today\" \n end tell"
                    runAppleScript(script: appleSriptCodeChangeThingsToday)
                    
                } else {
                    print("Create new Task in Things")
                    print(bodyContent)
                    
                    let appleSriptCodeChangeThingsToday = "tell application \"Things\" \n tell area \"Taskpaper\" \n set newToDo to make new to do ¬ \n with properties {name:\"\(bodyContent)\"} \n end tell \n end tell \n \n tell application \"Things\" \n set toDo to to do named \"\(bodyContent)\" \n move toDo to list \"Today\" \n end tell"
                    runAppleScript(script: appleSriptCodeChangeThingsToday)
                }
            }
        }

        //Mark done TPTasks as complete in Things
        //Get all items with done dates
        for item: ItemType in items {
            if item.hasAttribute("data-done") {
                    tpItemsDoneArray.append(item)
            }
        }
        
        //Done: Find matching things tasks and taskpaper tasks
        for tpToDo in tpItemsDoneArray {
            for thingsToDo in thingsItemArray {
                
                let bodyContent = removeTags(text: tpToDo.body)
                
                if thingsToDo.name == bodyContent {
                    
                    print(thingsToDo.name)
                    print(bodyContent)
                    
                    //Mark as completed if complete
                    if thingsToDo.comDate == "missing value" {
                        let appleSriptCodeChangeThingsToday = "tell application \"Things\" \n set toDo to to do named \"\(thingsToDo.name)\" \n set completion date of toDo to current date \n end tell"
                        runAppleScript(script: appleSriptCodeChangeThingsToday)
                        
                    } else {
                        
                        //Do nothing
                    }
                }
            }
        }


        
        
        
    }
    
    func runAppleScript(script: String) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error) {
                print(output.stringValue)
                
            } else if (error != nil) {
                print("error: \(error)")
            }
        }

    }
    
    func scheduleThingScript(name: String, date: NSDate) -> String {
        
        let appleSriptCodeChangeThingsStartDate = "to convertDate(textDate) \n set resultDate to the current date \n set the year of resultDate to (text 1 thru 4 of textDate) \n set the month of resultDate to (text 6 thru 7 of textDate) \n set the day of resultDate to (text 9 thru 10 of textDate) \n set the time of resultDate to 0 \n if (length of textDate) > 10 then \n set the hours of resultDate to (text 12 thru 13 of textDate) \n set the minutes of resultDate to (text 15 thru 16 of textDate) \n end if \n return resultDate \n end convertDate \n tell application \"Things\" \n set toDo to to do named \"\(name)\" \n set dateString to \"\(date)\" \n set remDateFormatted to my convertDate(dateString) \n schedule toDo for (remDateFormatted) \n end tell"

        return appleSriptCodeChangeThingsStartDate
    }
    
    func updateFileWithUpdates(outline: OutlineType) {
        let ud = UserDefaults.standard
        let string = ud.string(forKey: "filePath")
        
        do {
            try outline.serialize(nil).write(toFile: string!, atomically: false, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Error: \(error)")
        }
    }
    
    func removeTags(text:String) -> String{
        let stringArray = text.components(separatedBy: "@")
        
        let string = stringArray[0]
        
        let string2 = string.trimmingCharacters(in: NSCharacterSet.init(charactersIn: "-") as CharacterSet)
        
        let trimmedString = string2.trimmingCharacters(in: .whitespaces)
        
        return trimmedString
        
    }
    
    func stringToDate(string:String, tp:Bool) -> NSDate {
        
        let dateFormatter = DateFormatter()
        var date = NSDate()
        
        if tp == true {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.date(from: string)! as NSDate
            
        } else {
            
            let stringArray = string.components(separatedBy: " at ")
            
            let trimmedString = stringArray[0].trimmingCharacters(in: .whitespaces)
            
            dateFormatter.dateFormat = "EEEE, MMMM dd, yyyy"
            date = dateFormatter.date(from: trimmedString)! as NSDate
            
        }
        
        return date
        
    }
    
    func dateToString(date:NSDate) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let text = dateFormatter.string(from: date as Date)
        
        return text
        
    }
    
    func getDateType(item: ItemType, due: Bool) -> dateType {
        
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier:"en_US_POSIX")
        
        let helper = TaskHelper()
        var tpDueDateString = ""
        if due == true {
            tpDueDateString = (item.attributes["data-due"]! as String)
        } else {
            tpDueDateString = (item.attributes["data-start"]! as String)
            
        }
        let tpDueDate = dateFormatter.date(from: tpDueDateString)
        
        let now = Date()
        let nowDateString: String = dateFormatter.string(from: now)
        let nowDate = helper.stringToDate(string: nowDateString, tp: true)
        
        let cal = Calendar.current
        let nowComp = cal.dateComponents([.era, .year, .month, .day], from: nowDate as Date)
        let tpComp = cal.dateComponents([.era, .year, .month, .day], from: tpDueDate!)
        let today = cal.date(from: nowComp)
        let otherDate = cal.date(from: tpComp)
        
        let days = cal.dateComponents([Calendar.Component.day], from: (today! as Date), to: otherDate!)
        
        let dayInt = days.day
        
        if dayInt! <= 0 {
            print("today")
            return .Today
        } else if dayInt == 1 {
            print("tomorrow")
            return .Tomorrow
            
        } else if dayInt! > 1 && dayInt! <= 7 {
            print("this week")
            return .Week
            
        } else if dayInt! > 7 && dayInt! <= 30 {
            print("this month")
            return .Month
            
        } else {
            print("future")
            return .Future
            
        }
        
    }

}

