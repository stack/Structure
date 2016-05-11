//
//  Row.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/10/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import SQLite

public class Row {
    
    private let statement: Statement
    
    required public init(statement: Statement) {
        self.statement = statement
    }
    
    // MARK: - Double Values
    
    private subscript(index: Int32) -> Double {
        return sqlite3_column_double(statement.statement, index)
    }
    
    public subscript(index: Int) -> Double {
        return self[Int32(index)]
    }
    
    public subscript(key: String) -> Double {
        guard let index = statement.columns[key] else {
            return 0.0
        }
        
        return self[index]
    }
    
    // MARK: - Int Values
    
    private subscript(index: Int32) -> Int {
        let value = sqlite3_column_int(statement.statement, index)
        return Int(value)
    }
    
    public subscript(index: Int) -> Int {
        return self[Int32(index)]
    }
    
    public subscript(key: String) -> Int {
        guard let index = statement.columns[key] else {
            return 0
        }
        
        return self[index]
    }
    
    // MARK: - Int64 Values
    
    private subscript(index: Int32) -> Int64 {
        return sqlite3_column_int64(statement.statement, index)
    }
    
    public subscript(index: Int) -> Int64 {
        return self[Int32(index)]
    }
    
    public subscript(key: String) -> Int64 {
        guard let index = statement.columns[key] else {
            return 0
        }
        
        return self[index]
    }
    
    // MARK: - NSData Values
    
    private subscript(index: Int32) -> NSData? {
        let size = sqlite3_column_bytes(statement.statement, index)
        let data = sqlite3_column_blob(statement.statement, index)
        
        if size == 0 || data == nil {
            return nil
        }
        
        return NSData(bytes: data, length: Int(size))
    }
    
    public subscript(index: Int) -> NSData? {
        return self[Int32(index)]
    }
    
    public subscript(key: String) -> NSData? {
        guard let index = statement.columns[key] else {
            return nil
        }
        
        return self[index]
    }
    
    // MARK: - String Values
    
    private subscript(index: Int32) -> String? {
        let value = UnsafePointer<CChar>(sqlite3_column_text(statement.statement, index))
        return String.fromCString(value)
    }
    
    public subscript(index: Int) -> String? {
        return self[Int32(index)]
    }
    
    public subscript(key: String) -> String? {
        guard let index = statement.columns[key] else {
            return nil
        }
        
        return self[index]
    }
    
}
