//
//  NSNetService.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/2/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

extension NSNetService {
    class func servicesOfType(type : String, inDomain : String) {
        
    }
}

func errorForErrorDictionary(errorDictionary : [String: NSNumber]) -> NSError {
    return NSError(domain: NSNetServicesErrorDomain, code:(errorDictionary[NSNetServicesErrorCode]?.integerValue)!, userInfo:nil);
}
