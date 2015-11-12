//
//  SwiftAssociatedObjects.swift
//  SwiftAssociatedObjects
//
//  Created by Nathan Douglas on 11/12/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ObjectiveC

// Wraps a non-object value in an object so that we can store it with getAssociatedObject/setAssociatedObject.
final class Lifted<ValueType> {
  let value: ValueType
  init(_ x: ValueType) {
    self.value = x
  }
}

// A helper function to lift a non-object value to an object.
private func lift<T>(x: T) -> SwiftAssociatedObjects.Lifted<T>  {
  return SwiftAssociatedObjects.Lifted(x)
}

// A wrapper for objc_setAssociatedObject() that transparently handles non-objc values.
public func setAssociatedObject<ValueType>(object: AnyObject, value: ValueType, associativeKey: UnsafePointer<Void>) {
  if let v: AnyObject = value as? AnyObject {
    objc_setAssociatedObject(object, associativeKey, v, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  } else {
    objc_setAssociatedObject(object, associativeKey, SwiftAssociatedObjects.lift(value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}

// A wrapper for objc_getAssociatedObject() that transparently handles non-objc values.
public func getAssociatedObject<ValueType>(object: AnyObject, associativeKey: UnsafePointer<Void>) -> ValueType? {
  if let v = objc_getAssociatedObject(object, associativeKey) as? ValueType {
    return v
  } else if let v = objc_getAssociatedObject(object, associativeKey) as? SwiftAssociatedObjects.Lifted<ValueType> {
    return v.value
  } else {
    return nil
  }
}
