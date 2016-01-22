//
//  SQLite.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import SQLite

// Type aliases for common SQLite pointers
typealias SQLiteDatabase = COpaquePointer
typealias SQLiteStatement = COpaquePointer

// Proper import for the SQLite string memory functions
let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)

// Enum for SQLite results
public enum SQLiteResult {
    case OK
    case Error(Int32)
    case Row
    case Done
    case Unhandled(Int32)
    
    static func fromResultCode(code: Int32) -> SQLiteResult {
        switch code {
        case SQLITE_OK:
            return .OK
        case SQLITE_ERROR:
            return .Error(code)
        case SQLITE_ROW:
            return .Row
        case SQLITE_DONE:
            return .Done
        default:
            return .Unhandled(code)
        }
    }
}