//
//  Row.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/10/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import SQLite

/// A row represents a set of data returned from one iteration of Structure statement that returns data
public class Row {
    
    private let statement: Statement
    
    /**
        Initializes a new row, bound the given statement.
 
        - Parameters:
            - statement: The Structure statement that generated this row.
    
        - Returns: A new row, bound to the given statement.
    */
    required public init(statement: Statement) {
        self.statement = statement
    }
    
    // MARK: - Double Values
    
    /**
        Returns the double value for the given, native index value.
 
        - Parameters:
            - index: The index for the given value, as a native, C-API integer.
 
        - Returns: The double value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    private subscript(index: Int32) -> Double {
        return sqlite3_column_double(statement.statement, index)
    }
    
    /**
        Returns the double value for the given index value.
     
        - Parameters:
            - index: The index for the given value.
     
        - Returns: The double value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    public subscript(index: Int) -> Double {
        return self[Int32(index)]
    }
    
    /**
        Returns the double value for the given named index value.
     
        - Parameters:
            - index: The named index of the given value.
     
        - Returns: The double value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    public subscript(key: String) -> Double {
        guard let index = statement.columns[key] else {
            return 0.0
        }
        
        return self[index]
    }
    
    // MARK: - Int Values
    
    /**
        Returns the integer value for the given, native index value.
     
        - Parameters:
            - index: The index for the given value, as a native, C-API integer.
     
        - Returns: The integer value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    private subscript(index: Int32) -> Int {
        let value = sqlite3_column_int(statement.statement, index)
        return Int(value)
    }
    
    /**
        Returns the integer value for the given index value.
     
        - Parameters:
            - index: The index for the given value.
     
        - Returns: The integer value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    public subscript(index: Int) -> Int {
        return self[Int32(index)]
    }
    
    /**
        Returns the integer value for the given named index value.
     
        - Parameters:
            - index: The named index of the given value.
     
        - Returns: The integer value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    public subscript(key: String) -> Int {
        guard let index = statement.columns[key] else {
            return 0
        }
        
        return self[index]
    }
    
    // MARK: - Int64 Values
    
    /**
        Returns the 64-bit integer value for the given, native index value.
     
        - Parameters:
            - index: The index for the given value, as a native, C-API integer.
     
        - Returns: The 64-bit integer value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    private subscript(index: Int32) -> Int64 {
        return sqlite3_column_int64(statement.statement, index)
    }
    
    /**
        Returns the 64-bit integer value for the given index value.
     
        - Parameters:
            - index: The index for the given value.
     
        - Returns: The 64-bit integer value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    public subscript(index: Int) -> Int64 {
        return self[Int32(index)]
    }
    
    /**
        Returns the 64-bit integer value for the given named index value.
     
        - Parameters:
            - index: The named index of the given value.
     
        - Returns: The 64-bit integer value associated with the index, transforms by the underlying SQLite API if necessary.
    */
    public subscript(key: String) -> Int64 {
        guard let index = statement.columns[key] else {
            return 0
        }
        
        return self[index]
    }
    
    // MARK: - NSData Values
    
    /**
        Returns the data value for the given, native index value.
     
        - Parameters:
            - index: The index for the given value, as a native, C-API integer.
     
        - Returns: The data value associated with the index, transforms by the underlying SQLite API if necessary, or `nil` if the underlying value is `NULL`.
    */
    private subscript(index: Int32) -> Data? {
        let size = sqlite3_column_bytes(statement.statement, index)
        
        if let data = sqlite3_column_blob(statement.statement, index) {
            return Data(bytes: UnsafePointer<UInt8>(data), count: Int(size))
        } else {
            return nil
        }
    }
    
    /**
        Returns the data value for the given index value.
     
        - Parameters:
            - index: The index for the given value.
     
        - Returns: The data value associated with the index, transforms by the underlying SQLite API if necessary, or `nil` if the underlying value is `NULL`.
    */
    public subscript(index: Int) -> Data? {
        return self[Int32(index)]
    }
    
    /**
        Returns the data value for the given named index value.
     
        - Parameters:
            - index: The named index of the given value.
     
        - Returns: The data value associated with the index, transforms by the underlying SQLite API if necessary, or `nil` if the underlying value is `NULL`.
    */
    public subscript(key: String) -> Data? {
        guard let index = statement.columns[key] else {
            return nil
        }
        
        return self[index]
    }
    
    // MARK: - String Values
    
    /**
        Returns the string value for the given, native index value.
     
        - Parameters:
            - index: The index for the given value, as a native, C-API integer.
     
        - Returns: The string value associated with the index, transforms by the underlying SQLite API if necessary, or `nil` if the underlying value is `NULL`.
    */
    private subscript(index: Int32) -> String? {
        if let value = UnsafePointer<CChar>(sqlite3_column_text(statement.statement, index)) {
            return String(validatingUTF8: value)
        } else {
            return nil
        }
    }
    
    /**
        Returns the string value for the given index value.
     
        - Parameters:
            - index: The index for the given value.
     
        - Returns: The string value associated with the index, transforms by the underlying SQLite API if necessary, or `nil` if the underlying value is `NULL`.
    */
    public subscript(index: Int) -> String? {
        return self[Int32(index)]
    }
    
    /**
        Returns the string value for the given named index value.
     
        - Parameters:
            - index: The named index of the given value.
     
        - Returns: The string value associated with the index, transforms by the underlying SQLite API if necessary, or `nil` if the underlying value is `NULL`.
    */
    public subscript(key: String) -> String? {
        guard let index = statement.columns[key] else {
            return nil
        }
        
        return self[index]
    }
    
}
