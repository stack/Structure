//
//  Statement.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/1/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import SQLite

/// A wrapper around the SQLite statement
public class Statement {
    
    // MARK: - Properties
    
    internal let structure: Structure
    internal var statement: SQLiteStatement? = nil
    
    internal var bindParameters: [String:Int32] = [String:Int32]()
    internal var columns: [String:Int32] = [String:Int32]()
    
    
    // MARK: - Initialization
    
    internal init(structure: Structure, query: String) throws {
        // Store the structure
        self.structure = structure
        
        // Attempt to build the statement
        let result = sqlite3_prepare_v2(structure.database, query, -1, &statement, nil)
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
    
    /**
        Finalize the statement, freeing any resources associated with it.
    */
    public func finalize() {
        let result = sqlite3_finalize(statement)
        if result != SQLITE_OK {
            fatalError("Failed to finalize the statement: \(result)")
        }
        
        statement = nil
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
    
    /**
        Reset the statement for reuse without rebuilding.
    */
    public func reset() {
        let result = sqlite3_reset(statement)
        if result != SQLITE_OK {
            fatalError("Failed to reset the statement: \(result)")
        }
    }
    
    
    // MARK: - Execution
    
    internal func step() -> SQLiteResult {
        let result = sqlite3_step(statement)
        return SQLiteResult.fromResultCode(result)
    }
    
    // MARK: - Data Binding
    
    /**
        Bind a `Bindable` value to the given index.
 
        - Parameters:
            - index: The index of the parameter to bind.
            - value: The `Bindable` value to assign to the index.
    */
    public func bind(_ index: Int, value: Bindable?) {
        bind(Int32(index), value: value)
    }
    
    /**
        Bind a `Bindable` value to the given native index.
     
        - Parameters:
            - index: The native index of the parameter to bind.
        - value: The `Bindable` value to assign to the native index.
    */
    private func bind(_ index: Int32, value: Bindable?) {
        let idx = Int32(index)
        
        // If we don't have a value, bind NULL
        guard let bindable = value else {
            sqlite3_bind_null(statement , idx)
            return
        }
        
        // Bind the appropriate type
        switch bindable {
        case let x as Double:
            sqlite3_bind_double(statement, idx, x)
        case let x as Int:
            sqlite3_bind_int(statement, idx, Int32(x))
        case let x as Int64:
            sqlite3_bind_int64(statement, idx, x)
        case let x as Data:
            sqlite3_bind_blob(statement, idx, x.bytes, Int32(x.length), SQLITE_TRANSIENT)
        case let x as String:
            sqlite3_bind_text(statement, idx, x, Int32(x.utf8.count), SQLITE_TRANSIENT)
        default:
            fatalError("Unhndled bindable type")
        }
    }
    
    /**
        Bind a `Bindable` value to the given index.
     
        - Parameters:
            - index: The named index of the parameter to bind.
        - value: The `Bindable` value to assign to the namaed index.
    */
    public func bind(_ key: String, value: Bindable?) {
        // Ensure we can map a parameter to an index
        guard let index = bindParameters[key] else {
            return
        }
        
        // Pass the index to the proper function
        bind(index, value: value)
    }
}
