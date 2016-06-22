//
//  SQLite.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import SQLite

/// Type aliases for common SQLite pointers
typealias SQLiteDatabase = OpaquePointer
typealias SQLiteStatement = OpaquePointer

/// Proper import for the SQLite string memory functions
let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/**
    A map of SQLite result codes to Swift-friendly values
 
    - OK: Successful result.
    - Error: SQL error or missing database.
    - Row: A row is ready.
    - Done: No more rows are ready.
    - Unhandled: Any of the other SQLite errors that are currently not handled.
*/
public enum SQLiteResult {
    case ok
    case error(Int32)
    case row
    case done
    case unhandled(Int32)
    
    /**
        Converts a SQLite error code to a `SQLiteResult`
 
        - Parameters:
            - code: The native, SQLite error code.
 
        - Returns: The equivalent `SQLiteResult` value, or `Unhandled` if the value is currently handled.
    */
    static func fromResultCode(_ code: Int32) -> SQLiteResult {
        switch code {
        case SQLITE_OK:
            return .ok
        case SQLITE_ERROR:
            return .error(code)
        case SQLITE_ROW:
            return .row
        case SQLITE_DONE:
            return .done
        default:
            return .unhandled(code)
        }
    }
}
