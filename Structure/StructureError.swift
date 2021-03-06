//
//  StructureError.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2017 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import SQLite

/**
    Errors specific to the Structure framework.
 
    - Error: An error specific to how the Structure framework works.
    - InternalError: An error generated by the underlying SQLite API.
*/
public enum StructureError: Error {
    case error(String)
    case internalError(Int, String)
    
    internal static func from(sqliteResult: Int) -> StructureError {
        if let errorMessage = sqlite3_errstr(Int32(sqliteResult)), let error = String(validatingUTF8: errorMessage) {
            return internalError(Int(sqliteResult), error)
        } else {
            return internalError(0, "Unknown error")
        }
    }
    
    internal static func from(sqliteResult: Int32) -> StructureError {
        return from(sqliteResult: Int(sqliteResult))
    }
}
