//
//  StructureError.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2015 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import sqlite3

public enum StructureError: ErrorType {
    case InternalError(Int, String)
    
    public static func fromSqliteResult(result: Int32) -> StructureError {
        let errorMessage = sqlite3_errstr(result)
        if let error = String.fromCString(errorMessage) {
            return InternalError(Int(result), error)
        } else {
            return InternalError(0, "Unknown error")
        }
    }
}