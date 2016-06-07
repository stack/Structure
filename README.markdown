# Structure

Structure is a [SQLite](https://sqlite.org "SQLite Home Page") wrapper, written in Swift. It is written specifically for the needs of the author, but any comments or criticisms are welcomed.

Structure wraps the basic CRUD pattern of a database's usage. All queries are run internally through a single, internal queue. While SQLite already provides thread safety, this provides a simple mechanism to perform an atomic series of commands, with rollback features.

## Basic Usage

If you are familiar with the SQLite C API, you should be familiar with Structure. Full examples are available in the `Structure Tests` folder.

```swift
    let structure = try Structre("/tmp/structure.db")
    
    let statement = try structure.prepare("INSERT INTO foo (b, c, d) VALUES (:B, :C, :D)")
    
    defer {
        statement.finalize()
    }
    
    statement.bind("B", value: "foo")
    statement.bind("C", value: 42.1)
    statement.bind("D", value: 42)
    
    try structure.perform(statement)
```

## Database Lifecycle

Use the `init(path:)` constructor for Structure to create a database at the specified path. The `init()` constructor creates a database in-memory. Once closed, the in-memory database is lost. When a reference to a Structure object is de-initialized, the underlying database is closed. You can specifically close a database using the `close()` method. Once closed, you should never attempt to access the Structure object.

## Creating and Managing Statements

Statement objects can only be created through the `prepare(query:)` method of a Structure object. A Statement should be cleaned up with the `finalize()` method after you are done with it. You can also use the `reset()` to reuse a Statement object once it has been executed.

Parameters in a Statement are required to be named. SQLite allows the use of ":", "@", and "$" to prefix parameters.

## Using Statements

Binding values to parameters is done via the `bind(index:, value:)` and `bind(key:, value:)` methods. The former is for binding to the index of the parameter. The latter is used to bind to the parameter name, minus the prefix. The value is Bindable, which is a protocol that currently wraps the Double, Int, Int64, NSData, and String types. The Bindable values are optional, which allows the setting of `NULL` for a value. Remember: SQLite parameter indexes start with 1, not 0.

To perform a Statement that does not return rows, use the `perform(statement:)` method on the Structure object. To perform a Statement that does return rows, use the `perform(statement:, rowCallback:)` method. For each row returned, a Row object will be provided, which allows subscript access to the values. The type to access the subscript must be explicit, meaning the following is not valid. 

```swift
    let value = row[0]
```

The proper way to retrieve the value is:

```swift
    let value: Int = row[0]
```

The subscript methods use the SQLite conversions internally to return the proper type. For example, although a column may be defined as `REAL`, you can retrieve the value as a String. The SQLite conversion rules apply.

Row subscripts can either be accessed via their index or their name. Remember, row subscripts start with 0, not 1.

A Statement can be stepped using the `step(statement:)` method, allowing for single row execution of Statement if desired.

## Transactions

In the event that you need to perform a series of queries in an atomic fashion, you can use the `transaction(block:)` method. An example usage would be to fetch a counter value, increment it, and update it in the database. Any number of Statements can be performed inside of the transaction block, which will all be queued serially inside of the Structure object.

Each transaction is wrapped in the SQLite `TRANSACTION` mechanism, allowing rollbacks and commits. To cause a rollback to occur, throw an error of any type. Otherwise, if a block completes successfully, the entire transaction is committed.

## License

Structure is copyright © 2016 Stephen H. Gerstacker. It is free software, and may be redistributed under the terms specified in the `LICENSE` file.

# Installation

Currently only Carthage is supported. Add the following to your `Cartfile`:

    github "stack/Structure"

