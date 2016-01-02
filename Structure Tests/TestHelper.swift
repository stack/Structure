//
//  TestHelper.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/1/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import XCTest

func XCTSuccess() {
    XCTAssertTrue(true)
}

func XCTSuccess(message: String) {
    XCTAssertTrue(true, message)
}
