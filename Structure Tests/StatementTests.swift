//
//  StatementTests.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/1/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import XCTest
@testable import Structure

class StatementTests: XCTestCase {

    // MARK: - Set Up & Tear Down
    
    var structure: Structure!
    
    override func setUp() {
        super.setUp()
        
        structure = try! Structure()
        try! structure.execute("CREATE TABLE foo (a INTEGER PRIMARY KEY AUTOINCREMENT, b TEXT, c REAL)")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    // MARK: - Prepare Tests
    
    func testPrepareInvalidStatement() {
        do {
            try structure.prepare("SELECT FOO BAR BAZ")
            XCTFail("Preparation of invalid query succeeded")
        } catch let e {
            XCTSuccess("Preparation of invalid query failed: \(e)")
        }
    }
    
    func testPrepareRequiresNamedParameters() {
        do {
            try structure.prepare("SELECT a FROM foo WHERE b = ?")
            XCTFail("Preparation of query with unnamed parameters succeeded")
        } catch let e {
            XCTSuccess("Preparation of query with unnamed parameters failed: \(e)")
        }
        
    }
    
    func testPrepareValidStatement() {
        do {
            let statement = try structure.prepare("SELECT a, b, c FROM foo WHERE b IS :ONE OR b IS $TWO OR c IS @THREE")
            
            XCTAssertEqual(3, statement.bindParameters.count)
            XCTAssertEqual(1, statement.bindParameters["ONE"])
            XCTAssertEqual(2, statement.bindParameters["TWO"])
            XCTAssertEqual(3, statement.bindParameters["THREE"])
            
            XCTAssertEqual(3, statement.columns.count)
            XCTAssertEqual(0, statement.columns["a"])
            XCTAssertEqual(1, statement.columns["b"])
            XCTAssertEqual(2, statement.columns["c"])
        } catch let e {
            XCTFail("Preparation of valid query failed: \(e)")
        }
    }
    
    // MARK: - Read / Write Tests
    
    func testInsertStatement() {
        do {
            // Ensure we have no rows
            let initialCount = countFoo()
            XCTAssertEqual(0, initialCount)
            
            // Insert a row
            let insertStatement = try structure.prepare("INSERT INTO foo (b, c) VALUES (:B, :C)")
            
            defer {
                insertStatement.finalize()
            }
            
            insertStatement.bind("B", value: "foo")
            insertStatement.bind("C", value: 42.1)
            
            try structure.perform(insertStatement, rowCallback: nil)
            
            // Ensure we have 1 row
            let updatedCount = countFoo()
            XCTAssertEqual(1, updatedCount)
            
            // Get the data that was inserted
            let lastId = structure.lastInsertedId
            let selectStatement = try structure.prepare("SELECT a, b, c FROM foo")
            
            defer {
                selectStatement.finalize()
            }
            
            try structure.perform(selectStatement) { row in
                let a: Int64 = row["a"]
                let b: String? = row["b"]
                let c: Double = row["c"]
                
                XCTAssertEqual(lastId, a)
                XCTAssertEqual("foo", b)
                XCTAssertEqual(42.1, c)
            }
            
        } catch let e {
            XCTFail("Failed testing insert statement: \(e)")
        }
    }
    
    // MARK: - Utilities
    
    private func countFoo() -> Int {
        let statement = try! structure.prepare("SELECT COUNT(a) as count FROM foo")
        
        var count = -1
        try! structure.perform(statement) { row in
            count = row["count"]
        }
        
        return count
    }
    
}
