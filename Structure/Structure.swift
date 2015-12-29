//
//  Structure.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2015 Stephen H. Gerstacker. All rights reserved.
//

import sqlite3

public class Structure {
    
    // MARK: - Properties
    
    var database: SQLiteDatabase = nil
    
    internal var errorMessage: String {
        if let message = String.fromCString(sqlite3_errmsg(database)) {
            return message
        } else {
            return "<Unknown Error>"
        }
    }
    
    public internal(set) var userVersion: Int {
        get {
            // Prepare the statement
            var statement: SQLiteStatement = nil
            var result = sqlite3_prepare_v2(database, "PRAGMA user_version", -1, &statement, nil)
            if result != SQLITE_OK {
                fatalError("Preparing the user_version set statement should never fail: \(errorMessage)")
            }
            
            // Cleanup the statement when complete
            defer {
                sqlite3_finalize(statement)
            }
            
            // Execute the statement
            result = sqlite3_step(statement)
            if result == SQLITE_ROW {
                return Int(sqlite3_column_int(statement, 0))
            } else {
                fatalError("Reading the user_version get statement should never fail: \(errorMessage)")
            }
        }
        
        set {
            // Prepare the statement
            var statement: SQLiteStatement = nil
            var result = sqlite3_prepare_v2(database, "PRAGMA user_version = \(newValue)", -1, &statement, nil)
            if result != SQLITE_OK {
                fatalError("Preparing the user_version set statement should never fail: \(errorMessage)")
            }
            
            // Cleanup the statement when complete
            defer {
                sqlite3_finalize(statement)
            }
            
            // Execute the statement
            result = sqlite3_step(statement)
            if result != SQLITE_DONE {
                fatalError("Stepping the user_version set statement should never fail: \(errorMessage)")
            }
        }
    }
    
    
    // MARK: - Initialization
    
    convenience public init() throws {
        try self.init(path: ":memory:")
    }
    
    required public init(path: String) throws {
        // Attempt to open the path
        let result = sqlite3_open_v2(path, &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        if result != SQLITE_OK {
            throw StructureError.fromSqliteResult(result)
        }
    }
    
    deinit {
        if database != nil {
            sqlite3_close_v2(database)
        }
    }
    
}
