//
//  Structure.swift
//  Structure
//
//  Created by Stephen Gerstacker on 12/20/15.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import SQLite

/// A common identifier for use with dispatch queues
private let StructureQueueKey: DispatchSpecificKey<UnsafeMutablePointer<Void>> = DispatchSpecificKey()

/// Simplified type for the callback that happens per-row of a `perform` function.
public typealias PerformCallback = (Row) -> Void

private typealias EnsureVersionWrapper = (newVersion: Int, currentVersion: Int) throws -> ()
private typealias ErrorWrapper = (error: ErrorProtocol) throws -> ()


/// The root class of the Structure framework
public class Structure {
    
    // MARK: - Properties
    
    internal var database: SQLiteDatabase? = nil
    
    private var queue: DispatchQueue
    private var queueId: UnsafeMutablePointer<Void>
    
    internal var errorMessage: String {
        if let message = String(validatingUTF8: sqlite3_errmsg(database)) {
            return message
        } else {
            return "<Unknown Error>"
        }
    }
    
    /// The lasted ID generate
    public var lastInsertedId: Int64 {
        return sqlite3_last_insert_rowid(database)
    }
    
    /// A number store along with the database, typically used for schema versioning.
    public internal(set) var userVersion: Int {
        get {
            do {
                let statement = try prepare("PRAGMA user_version")
                
                defer {
                    statement.finalize()
                }
                
                var version = -1
                try perform(statement) { row in
                    version = row[0]
                }
                
                return version
            } catch let e {
                fatalError("Failed to read user version: \(e)")
            }
        }
        
        set {
            do {
                try execute("PRAGMA user_version = \(newValue)")
            } catch let e {
                fatalError("Failed to write user version: \(e)")
            }
        }
    }
    
    
    // MARK: - Initialization
    
    /**
        Initializes a new Structure object with all data stored in memory. No data will be persisted.
     
        - Throws: `StructureError.InternalError` if opening the database fails.
    */
    convenience public init() throws {
        try self.init(path: ":memory:")
    }
    
    /**
        Initializes a new Structure object at the given path. If the file already exists, it will be opened, otherwise it will be created.
 
        - Parameters:
            - path: The full path to the Structure object to open or create.
 
        - Throws: `StructureError.InternalError` if opening the database fails.
    */
    required public init(path: String) throws {
        // Build the execution queue
        queue = DispatchQueue(label: "Structure Queue", attributes: DispatchQueueAttributes.serial)
        queueId = UnsafeMutablePointer(allocatingCapacity: 1)
        queue.setSpecific(key: StructureQueueKey, value: queueId)
        
        // Attempt to open the path
        let result = sqlite3_open_v2(path, &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        if result != SQLITE_OK {
            throw StructureError.fromSqliteResult(result)
        }
    }
    
    /**
        Close a Structure object. Once closed, a Structure object should not be used again. The behaviour is undefined.
 
        - Throws: `StructureError.InternalError` if closing the database failed.
    */
    public func close() throws {
        var potentialError: StructureError? = nil
        
        dispatchWithinQueue {
            let result = sqlite3_close_v2(self.database)
            if result != SQLITE_OK {
                potentialError = StructureError.fromSqliteResult(result)
            } else {
                self.database = nil
            }
        }
        
        if let error = potentialError {
            throw error
        }
    }
    
    deinit {
        queue.setSpecific(key: StructureQueueKey, value: nil)
        queueId.deallocateCapacity(1)
        
        // Force a final closure, just in case
        if database != nil {
            sqlite3_close_v2(database)
        }
        
    }
    
    // MARK: - Statement Creation
    
    /**
        Creates a new statement with the query string. Queries are validated and must have all parameters named.
 
        - Throws: 
            `StructureError.InternalError` if parsing by SQLite has failed.
            `Structure.Error` if a parameter is not named properly.
     
        - Returns: A new Statement object.
    */
    public func prepare(_ query: String) throws -> Statement {
        return try Statement(structure: self, query: query)
    }
    
    // MARK: - Thread Safety
    
    internal func dispatchWithinQueue(_ block: @noescape (Void) -> ()) {
        let currentId = DispatchQueue.getSpecific(key: StructureQueueKey)
        if currentId == queueId {
            block()
        } else {
            queue.sync(execute: block)
        }
    }
    
    // MARK: - Execution
    
    /**
        A shortcut method to execute a query without using the `prepare` and `finalize` functions.
 
        - Parameters:
            - query: The query to execute
 
        - Throws: `StructureError.InternalError` if the execution failed.
    */
    public func execute(_ query: String) throws {
        // Placeholder for an error that occurs in the block
        var potentialError: StructureError? = nil
        
        // Queue the execution
        dispatchWithinQueue {
            // Attempt the execution
            var errorMessage: UnsafeMutablePointer<Int8>? = nil
            let result = sqlite3_exec(self.database, query, nil, nil, &errorMessage)
            if result != SQLITE_OK {
                if let message = String(validatingUTF8: errorMessage!) {
                    potentialError = StructureError.internalError(Int(result), message)
                } else {
                    potentialError = StructureError.internalError(Int(result), "<Unknown exec error>")
                }
                
                sqlite3_free(errorMessage)
            }
        };
        
        // If an error occurred in the block, throw it
        if let error = potentialError {
            throw error
        }
    }
    
    /**
        Performs the given Statement that does not return any rows.
 
        - Parameters:
            - statement: The statement to perform.
 
        - Throws: `Structure.InternalError` if performing the Statement failed.
    */
    public func perform(_ statement: Statement) throws {
        var potentialError: StructureError? = nil
        
        dispatchWithinQueue {
            // Step until there is an error or complete
            var keepGoing = true
            while keepGoing {
                let result = statement.step()
                
                switch result {
                case .done:
                    keepGoing = false
                case .error(let code):
                    potentialError = StructureError.fromSqliteResult(code)
                    keepGoing = false
                case .ok:
                    keepGoing = false
                case .row:
                    potentialError = StructureError.error("Performed a statement without a row callback, and got a row")
                case .unhandled(let code):
                    fatalError("Unhandled result code from stepping a statement: \(code)")
                }
            }
        }
        
        if let error = potentialError {
            throw error
        }
    }
    
    /**
        Performs the given Statement, calling the given callback for each row returned.
 
        - Parameters:
            - statement: The statement to perform.
            - rowCallback: The callback performed for each row that results from the Statement.
 
        - Throws: `Structure.InternalError` if performing the Statement failed.
    */
    // TODO: Swift 3 bug: public func perform(_ statement: Statement, rowCallback: @noescape PerformCallback) throws {
    public func perform(_ statement: Statement, rowCallback: @noescape (Row) -> Void) throws {
        var potentialError: StructureError? = nil
        
        dispatchWithinQueue {
            // Step until there is an error or complete
            var keepGoing = true
            while keepGoing {
                let result = statement.step()
                
                switch result {
                case .done:
                    keepGoing = false
                case .error(let code):
                    potentialError = StructureError.fromSqliteResult(code)
                    keepGoing = false
                case .ok:
                    keepGoing = false
                case .row:
                    rowCallback(Row(statement: statement))
                case .unhandled(let code):
                    fatalError("Unhandled result code from stepping a statement: \(code)")
                }
            }
        }
        
        if let error = potentialError {
            throw error
        }
    }
    
    /**
        Performs one iteration of a given statement.
 
        - Parameters:
            - statement: The statement to perform.
 
        - Throws: `StructureError.InternalError` if performing the statement failed.
 
        - Returns: A row from a single execution of the Statement, or nil if the query did not return a row.
    */
    public func step(_ statement: Statement) throws -> Row? {
        var potentialError: StructureError? = nil
        var potentialRow: Row? = nil
        
        dispatchWithinQueue {
            let result = statement.step()
            
            switch result {
            case .done:
                potentialRow = nil
            case .error(let code):
                potentialError = StructureError.fromSqliteResult(code)
            case .ok:
                potentialRow = nil
            case .row:
                potentialRow = Row(statement: statement)
            case .unhandled(let code):
                fatalError("Unhandled result code from stepping a statement: \(code)")
            }
        }
        
        if let error = potentialError {
            throw error
        }
        
        return potentialRow
    }
    
    /**
        Any Statements performed within the given block will be wrapped in a transaction, 
        allowing single execution of all Statements and rollback for failed executions.
 
        - Parameters:
            - block: The block containg Statements to be executed in one concurrent transaction.
 
        - Throws: `StructureError.InternalError` if an error is thrown inside of the block.
    */
    public func transaction(block: @noescape (structure: Structure) throws -> ()) rethrows {
        try transaction(block: block, onError: { throw $0 })
    }
    
    // TODO: Swift 3 bug: private func transaction(block: @noescape (structure: Structure) throws -> (), onError: @noescape OnErrorWrapper) rethrows {
    private func transaction(block: @noescape (structure: Structure) throws -> (), onError: @noescape (error: ErrorProtocol) throws -> ()) rethrows {
    
        var potentialError: ErrorProtocol? = nil
        
        queue.sync { 
            // Mark the beginning of the transaction
            self.beginTransaction()
            
            do {
                try block(structure: self)
                self.commitTransaction()
            } catch let e {
                potentialError = e
                self.rollbackTransaction()
            }
        }
        
        if let error = potentialError {
            try onError(error: error)
        }
    }
    
    
    // MARK: - Migration
    
    /**
        Performs the Statements in the given block, ensuring they are only executed
        when `userVersion` is one less than the given version. This ensures the same
        set of migration blocks can be run multiple times, only allowing new migration
        versions to be run. Once completed, the userVersion is incremented to the
        given version.
 
        - Parameters:
            - version: The incremental version number of the migration, starting at 1.
            - migration: A block containing Statements executed to perform a migration.
 
        - Throws: `StructureError.InternalError` if an error is thrown inside of the block.
    */
    public func migrate(version: Int, migration: @noescape (structure: Structure) throws -> ()) rethrows {
        try migrate(version: version,
                    migration: migration,
                    ensureVersion: {
                        guard $0 - $1 == 1 else {
                            throw StructureError.error("Attempted migration \($0) is out of order with \($1)")
                        }
                    },
                    onError: {
                        throw $0
                    })
    }
    
    // TODO: Swift 3 bug: private func migrate(version: Int, migration: @noescape (structure: Structure) throws -> (), ensureVersion: @noescape EnsureVersionWrapper, onError: @noescape OnErrorWrapper) rethrows {
    private func migrate(version: Int, migration: @noescape (structure: Structure) throws -> (), ensureVersion: @noescape (newVersion: Int, currentVersion: Int) throws -> (), onError: @noescape (error: ErrorProtocol) throws -> ()) rethrows {
        // Skip if this migration has already run
        guard userVersion < version else {
            return
        }
        
        // Error if this migration is out of order
        try ensureVersion(newVersion: version, currentVersion: userVersion)
        
        // Submit the
        var potentialError: ErrorProtocol? = nil
        
        dispatchWithinQueue {
            self.beginTransaction()
            
            do {
                try migration(structure: self)
                self.userVersion = version
                self.commitTransaction()
            } catch let e {
                potentialError = e
                self.rollbackTransaction()
            }
        }
        
        if let error = potentialError {
            try onError(error: error)
        }
    }
    
    // MARK: - Transaction Management
    
    private func beginTransaction() {
        let result = sqlite3_exec(database, "BEGIN TRANSACTION", nil, nil, nil)
        if result != SQLITE_OK {
            fatalError("BEGIN TRANSACTION should never fail")
        }
    }
    
    private func commitTransaction() {
        let result = sqlite3_exec(database, "COMMIT TRANSACTION", nil, nil, nil)
        if result != SQLITE_OK {
            fatalError("COMMIT TRANSACTION should never fail")
        }
    }
    
    private func rollbackTransaction() {
        let result = sqlite3_exec(database, "ROLLBACK TRANSACTION", nil, nil, nil)
        if result != SQLITE_OK {
            fatalError("ROLLBACK TRANSACTION should never fail")
        }
    }
}
