//
//  Statement.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/1/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import sqlite3

public class Statement {
    
    // MARK: - Properties
    
    internal var statement: SQLiteStatement = nil
    
    internal var bindParameters: [String:Int32] = [String:Int32]()
    internal var columns: [String:Int32] = [String:Int32]()
    
    
    // MARK: - Initialization
    
    internal init(database: SQLiteDatabase, query: String) throws {
        // Attempt to build the statement
        let result = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        if result != SQLITE_OK {
            throw StructureError.fromSqliteResult(result)
        }
        
        // Parse the information from the statement
        try parseBindParameters()
        try parseColumns()
    }
    
    deinit {
        if statement != nil {
            sqlite3_finalize(statement)
        }
    }
    
    private func parseBindParameters() throws {
        let count = sqlite3_bind_parameter_count(statement)
        
        if count > 0 {
            for idx in 1 ... count {
                let bindName = sqlite3_bind_parameter_name(statement, idx)
                
                // We need to have a readable name
                guard let name = String.fromCString(bindName) else {
                    throw StructureError.Error("Bind parameter \(idx) was not named")
                }
                
                // The name must not be empty
                if name.isEmpty {
                    throw StructureError.Error("Bind parameter \(idx) has an empty name")
                }
                
                // The name must start with a valid token
                let nameIndex = name.startIndex.successor()
                let token = name.substringToIndex(nameIndex)
                
                if token != ":" && token != "$" && token != "@" {
                    throw StructureError.Error("Bind parameter \(idx) has an invalid name of \(name)")
                }
                
                // Valid, so get the name without the token
                let finalName = name.substringFromIndex(nameIndex)
                bindParameters[finalName] = idx
            }
        }
    }
    
    private func parseColumns() throws {
        let count = sqlite3_column_count(statement)
        for idx in 0 ..< count {
            let columnName = sqlite3_column_name(statement, idx)
            
            // Ensre we can use the name
            guard let name = String.fromCString(columnName) else {
                throw StructureError.Error("Column \(idx) was not named")
            }
            
            // Valid, store the name
            columns[name] = idx
        }
    }
}
