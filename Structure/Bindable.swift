//
//  Bindable.swift
//  Structure
//
//  Created by Stephen Gerstacker on 1/10/16.
//  Copyright © 2016 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

/// A protocol to define an type as bindable to a Structure statement
public protocol Bindable {
    
}

/// Double is a Bindable type
extension Double: Bindable {
    
}

/// NSData is a Bindable type
extension NSData: Bindable {
    
}

/// Int is a Bindable type
extension Int: Bindable {
    
}

/// Int64 is a Bindable type
extension Int64: Bindable {
    
}

/// String is a Bindable type
extension String: Bindable {
    
}
