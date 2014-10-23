//
//  SwiftSQL.swift
//  SwiftSQL
//
//  Created by Remi Robert on 20/08/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import Foundation

class CamembertModel :NSObject {
    
    private var nameTable :String! = nil
    var id :Int? = nil
    
    func setId(id :Int) {
        self.id = id
    }
        
    func push() {
        if self.id != nil {
            return Void()
        }
        var requestPush = "INSERT INTO " + self.nameTable + " ("

        for var index = 1; index < reflect(self).count; index++ {
            switch index {
            case reflect(self).count - 1 : requestPush += reflect(self)[index].0 + ")"
            default: requestPush += reflect(self)[index].0 + ", "
            }
        }
        requestPush += " VALUES ("
        for var index = 1; index < reflect(self).count; index++ {
            var currentValue = reflect(self)[index].1.value
            
            switch currentValue {
            case let v where (currentValue as? TEXT != nil): requestPush += "\"\(currentValue)\""
            default: requestPush += "\(currentValue)"
            }
            
            switch index {
            case reflect(self).count - 1: requestPush += ");"
            default: requestPush += ", "
            }
        }
        camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
            requestPush.cStringUsingEncoding(NSUTF8StringEncoding)!)
        self.id = Int(sqlite3_last_insert_rowid(DataAccess.access.dataAccess))
    }
    
    func update() {
        if self.id == -1 {
            return Void()
        }
        var requestUpdate :String = "UPDATE \(self.nameTable) SET "
        
        for var index = 1; index < reflect(self).count; index++ {
            var currentValue = reflect(self)[index].1.value
            
            switch currentValue {
            case let v where (currentValue as? TEXT != nil): requestUpdate += "\(reflect(self)[index].0) = \"\(currentValue)\""
            default: requestUpdate += "\(reflect(self)[index].0) = \(currentValue)"
            }
            
            switch index {
            case reflect(self).count - 1: requestUpdate += " WHERE id = \(self.id!);"
            default: requestUpdate += ", "
            }
        }
        println("request : \(requestUpdate)")
        
        camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
            requestUpdate.cStringUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    func remove() {
        if self.id == nil {
            return Void()
        }
        var requestDelete :String = "DELETE FROM \(self.nameTable) WHERE id=\(self.id!)"
        
        camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
            requestDelete.cStringUsingEncoding(NSUTF8StringEncoding)!)
        self.id = -1
    }
    
    func getSchemaTable() -> [String]! {
        var arraySirng :[String] = []
        
        for var index = 1; index < reflect(self).count; index++ {
            let reflectionClass = reflect(self)[index]
            let currentValue = reflectionClass.1.value

            switch currentValue {
            case let v where (currentValue as? INTEGER != nil):
                arraySirng.append("\(reflectionClass.0) INTEGER")
            case let v where (currentValue as? REAL != nil):
                arraySirng.append("\(reflectionClass.0) REAL")
            case let v where (currentValue as? TEXT != nil):
                arraySirng.append("\(reflectionClass.0) TEXT")
            default: return nil
            }
        }
        return arraySirng
    }
    
    func isTableExist() -> Bool {
        for currentTable in Camembert.getListTable() {
            if currentTable == self.nameTable {
                return true
            }
        }
        return false
    }
    
    class func getNameTable(inout tmpNameTable :String) -> String {
        let parseString = "0123456789"
        
        for currentNumberParse in parseString {
            var parseName = tmpNameTable.componentsSeparatedByString(String(currentNumberParse))
            if parseName.count > 0 {
                tmpNameTable = parseName[parseName.count - 1]
            }
        }
        return tmpNameTable
    }
    
    func _initNameTable() {
        var tmpNameTable = NSString(CString: object_getClassName(self), encoding: NSUTF8StringEncoding) as String
        self.nameTable = CamembertModel.getNameTable(&tmpNameTable).componentsSeparatedByString(".")[1]
    }
    
    func sendRequest(inout ptrRequest :COpaquePointer, request :String) -> Bool {
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            request.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
            return false
        }
        return true
    }
    
    func createTable() -> Bool {
        if self.isTableExist() == false {
            var requestCreateTable :String = "CREATE TABLE " + self.nameTable + " (id INTEGER PRIMARY KEY AUTOINCREMENT, "
            if let configurationTable = self.getSchemaTable() {
                for var index = 0; index < configurationTable.count; index++ {
                    switch index {
                    case configurationTable.count - 1: requestCreateTable += configurationTable[index]
                    default: requestCreateTable += configurationTable[index] + ", "
                    }
                }
                requestCreateTable += ");"
                var request :COpaquePointer = nil
                camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
                    requestCreateTable.cStringUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        return true
    }
    
    class func numberElement() -> Int {
        var tmpNameTable = NSString(CString: class_getName(self), encoding: NSUTF8StringEncoding) as String
        tmpNameTable = tmpNameTable.componentsSeparatedByString(".")[1]
        var requestNumberlement :String = "SELECT COUNT(*) FROM \(CamembertModel.getNameTable(&tmpNameTable));"
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestNumberlement.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
            return 0
        }
        if sqlite3_step(ptrRequest) == SQLITE_ROW {
            return Int(sqlite3_column_int(ptrRequest, 0))
        }
        return 0
    }
    
    func _initWithId(id :Int) {
        var requestInit :String = "SELECT * FROM \(self.nameTable) WHERE id=\(id);"
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestInit.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
            return Void()
        }

        if sqlite3_step(ptrRequest) == SQLITE_ROW {
            for var index = 0; index < reflect(self).count; index++ {
                if index == 0 {
                    self.id = Int(sqlite3_column_int(ptrRequest, 0))
                }
                else {
                    var currentTypeData = sqlite3_column_type(ptrRequest, CInt(index))
                    switch currentTypeData {
                    case SQLITE_INTEGER:
                        self.setValue((Int(sqlite3_column_int(ptrRequest, CInt(index))) as AnyObject),
                            forKey: reflect(self)[index].0)
                    case SQLITE_FLOAT:
                        self.setValue((Float(sqlite3_column_double(ptrRequest, CInt(index))) as AnyObject),
                            forKey: reflect(self)[index].0)
                    case SQLITE_TEXT:
                        var stringValue = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(ptrRequest, CInt(index))))                        
                        self.setValue((String(stringValue!) as AnyObject), forKey: reflect(self)[index].0)
                    default: Void()
                    }
                }
            }
        }
    }
    
    override init() {
        super.init()
        self._initNameTable()
        self.createTable()
    }
    
    init(id :Int) {
        super.init()
        self._initNameTable()
        self.createTable()
        self._initWithId(id)
    }
}