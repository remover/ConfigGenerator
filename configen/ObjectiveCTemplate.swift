//
//  ObjectiveCTemplate.swift
//  configen
//
//  Created by Dónal O'Brien on 11/08/2016.
//  Copyright © 2016 The App Business. All rights reserved.
//

import Foundation

protocol Template {
  var token: String { get }
  var customTypeToken: String { get }
  var doubleDeclaration: String { get }
  var integerDeclaration: String { get }
  var stringDeclaration: String { get }
  var booleanDeclaration: String { get }
  var urlDeclaration: String { get }
  var customDeclaration: String { get }
  var foundationImport: String { get }
  
  var outputClassHeaderName: String { get }
  var autoGenerationComment: String { get }
  var headerBody: String { get }
}

struct ObjectiveCTemplate: Template {
  
  let optionsParser: OptionsParser
  
  let token = "$$"
  let customTypeToken = "$$$"
  var doubleDeclaration: String { return "+ (NSNumber *)\(token)" }
  var integerDeclaration: String { return "+ (NSNumber *)\(token)" }
  var stringDeclaration: String { return "+ (NSString *)\(token)" }
  var booleanDeclaration: String { return "+ (BOOL *)\(token)" }
  var urlDeclaration: String { return "+ (NSURL *)\(token)" }
  var customDeclaration: String { return "+ (\(customTypeToken))\(token)" }
  var foundationImport: String { return "#import <Foundation/Foundation.h>\n\n" }
  
  var autoGenerationComment: String {
    return"// auto-generated by \(optionsParser.appName)\n\n"
  }
  
  var headerBody: String {
    return "@interface \(optionsParser.outputClassName) : NSObject \n\(token)\n@end\n"
  }
  
  var outputClassHeaderName: String {
    return "\(optionsParser.outputClassDirectory)/\(optionsParser.outputClassName).h"
  }
}


struct FileGenerator {
  
  func generateHeaderFile(withTemplate template: Template, options: OptionsParser) {
    
    var headerBodyContent = ""
    for (variableName, type) in options.hintsDictionary() {
      let headerLine = methodDeclarationForVariableName(variableName, type: type, template: template)
      headerBodyContent.appendContentsOf("\n" + headerLine + ";" + "\n")
    }
    
    var headerBody = template.headerBody
    headerBody.replace(template.token, withString: headerBodyContent)
    
    do {
      let headerOutputString = template.autoGenerationComment + template.foundationImport + headerBody
      try headerOutputString.writeToFile(template.outputClassHeaderName, atomically: true, encoding: NSUTF8StringEncoding)
    }
    catch {
      fatalError("Failed to write to file at path \(template.outputClassHeaderName)")
    }
    
  }
  
  func methodDeclarationForVariableName(variableName: String, type: String, template: Template) -> String {
    var line = ""
    
    switch (type) {
    case ("Double"):
      line += template.doubleDeclaration
      
    case ("Int"):
      line += template.integerDeclaration
      
    case ("String"):
      line += template.stringDeclaration
      
    case ("Bool"):
      line += template.booleanDeclaration
      
    case ("NSURL"):
      line += template.urlDeclaration
      
    default:
      fatalError("Unknown type: \(type)")
    }
    
    line.replace(template.token, withString: variableName)
    
    return line
  }
  
}

extension String {
  mutating func replace(token: String, withString string: String) {
    self = stringByReplacingOccurrencesOfString(token, withString: string)
  }
}

