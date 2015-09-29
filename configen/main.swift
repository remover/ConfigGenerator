//
//  main.swift
//  configen
//
//  Created by Sam Dods on 29/09/2015.
//  Copyright © 2015 The App Business. All rights reserved.
//

import Foundation

extension String {
  var trimmed: String {
    return (self as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
  }
}

let arguments = NSProcessInfo.processInfo().arguments
guard arguments.count == 5 else {
  fatalError("usage: \(arguments.first!) <inputPlistFilePath> <inputHintsFilePath> <outputClassName> <outputClassDirectory>")
}

let inputPlistFilePath = arguments[1]
let inputHintsFilePath = arguments[2]
let outputClassName = arguments[3]
let outputClassDirectory = arguments[4]
let outputClassFileName = "\(outputClassDirectory)/\(outputClassName).swift"

guard let data = NSData(contentsOfFile: inputPlistFilePath) else {
  fatalError("No data at path: \(inputPlistFilePath)")
}

guard let plistDictionary = (try? NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil)) as? Dictionary<String, AnyObject> else {
  fatalError()
}

guard let hintsString = try? NSString(contentsOfFile: inputHintsFilePath, encoding: NSUTF8StringEncoding) else {
  fatalError("No data at path: \(inputHintsFilePath)")
}

var hintsDictionary = Dictionary<String, String>()

let hintLines = hintsString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
for hintLine in hintLines where hintLine.trimmed.characters.count > 0 {
  let hints = hintLine.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ":")).map { $0.trimmed }
  guard hints.count == 2 else {
    fatalError("Expected \"variableName : Type\", instead of \"\(hintLine)\"")
  }
  let (variableName, type) = (hints[0], hints[1])
  hintsDictionary[variableName] = type
}

var outputString = ""

for (variableName, type) in hintsDictionary {
  guard let value = plistDictionary[variableName] else {
    fatalError("No configuration setting for variable name: \(variableName)")
  }
  
  var line = ""
  
  switch (type) {
    case ("Double"):
      line = "\(variableName): Double = \(Double(value as! NSNumber))"
    
    case ("Int"):
      line = "\(variableName): Int = \(Int(value as! NSNumber))"
      
    case ("String"):
      line = ("\(variableName): String = \"\(value as! String)\"")
      
    case ("Bool"):
      let boolString = value as! Bool ? "true" : "false"
      line = "\(variableName): Bool = \(boolString)"
      
    case ("NSURL"):
      let url = NSURL(string: value as! String)!
      guard url.host != nil else {
        fatalError("Found URL without host: \(url) for setting: \(variableName)")
      }
      line = "\(variableName): NSURL = NSURL(string: \"\(value)\")!"
      
    default:
      fatalError("Unknown type: \(type)")
  }
  
  outputString.appendContentsOf("  static let " + line + "\n")
}

outputString = "class \(outputClassName) {\n\(outputString)}\n"

do {
  try outputString.writeToFile(outputClassFileName, atomically: true, encoding: NSUTF8StringEncoding)
}
catch {
  fatalError("Failed to write to file at path \(outputClassFileName)")
}
