//
//  ContexterClasses.swift
//  contexter
//
//  Created by Aleksey Sevruk on 11/19/17.
//  Copyright © 2017 Aleksey Sevruk. All rights reserved.
//

import Foundation

class ContexterClasses {
    
    var dict = [Int: String]()
    
    func getLabel(cls: Int) -> String {
        let label = dict[cls]
        return label == nil ? "" : label!
    }
    
    func getSize() -> Int {
        return dict.count
    }
    
    public init() {
        dict[0] = "all"
        dict[1] = "efes"
        dict[2] = "loreal"

    }
    
}
