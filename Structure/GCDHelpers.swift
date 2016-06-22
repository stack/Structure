//
//  File.swift
//  Structure
//
//  Created by Stephen Gerstacker on 6/16/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

@_silgen_name("dispatch_sync") internal func os_dispatch_sync(_ queue: DispatchQueue, @noescape _ block: dispatch_block_t)
