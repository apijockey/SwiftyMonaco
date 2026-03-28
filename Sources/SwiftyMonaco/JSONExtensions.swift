//
//  JSONExtensions.swift
//  SwiftyMonaco
//
//  Created by Patric Dubois on 17.03.26.
//
import Foundation

extension String {
    func escapeSpecialCharacters() -> String {
        var newText = self
        if self.contains("This is much better"){
         
        }
        newText = newText.replacingOccurrences(of: "\"", with: "\\\"")
        //newText = newText.replacingOccurrences(of: "\\", with: "\\\\")
        newText = newText.replacingOccurrences(of: "\n", with: "\\n")
        newText = newText.replacingOccurrences(of: "\t", with: "\\t")
        newText = newText.replacingOccurrences(of: "\r", with: "\\r")
        return newText
    }
}

extension Any? {
    public var jsonString : String {
        if  let text = self as? String {
            
            return text.escapeSpecialCharacters()
        }
        else if let dict = self as? [String:Any?] {
            return dict.jsonString
        }
        
        else if let array = self as? [Any] {
            return array.jsonString
        }
        else if let bool = self as? Bool {
            return String(bool)
        }
        else if let number = self as? Int {
            return String(number)
        }
        else if let number = self as? Float {
            return String(number)
        }
        else if let number = self as? Double {
            return String(number)
        }
        else if let data = self as? Data {
            return String(data : data, encoding: .utf8) ?? ""
        }
        else {
            return ""
        }
    }
   
    
//    public var arrayStringValue : String {
//        if  let text = self as? String {
//            return text
//        }
//        else if let dict = self as? [String:Any] {
//            return dict.arrayStringValue
//        }
//        else if let array = self as? [Any] {
//            return array.arrayStringValue
//        }
//        else {
//            return ""
//        }
//    }
}


import Foundation

public typealias JsonAny = Any?
public typealias JsonArray = [JsonAny]
public typealias JsonDictionary = [String: JsonAny]


extension JsonAny {

    
    func toBool() -> Bool? {

        switch self {
        case let bool as Bool:
            return bool
        case let int as Int:
            return int == 0 ? false : true
        case let double as Double:
            return double == 0 ? false : true
        case let string as String:
            return string == "true"
        
        default:
            return nil
        }
    }

    
    func toDouble() -> Double? {
        switch self {
        case let double as Double:
            return double
        case let int as Int:
            return Double(int)
        default:
            return nil
        }
    }

    
    func toInt() -> Int? {
        switch self {
        case let double as Double:
            return Int(double)
        case let int as Int:
            return int
        default:
            return nil
        }
    }

    
    func toString() -> String? {
        switch self {
        case let string as String:
            return string
            
        default:
            return nil
        }
    }
}

extension Dictionary where Key == String, Value == Any?{
    public var jsonString  : String {
        var resultString = "{"
        self.forEach { element in
           
            resultString.append("\"")
            resultString.append(element.key)
            resultString.append("\"")
            resultString.append(":")
            if let dict = element.value as? [String: Any?]  {
               
                resultString.append(dict.jsonString)
                resultString.append(",")
            }
            else if let dict = element.value as? [String: Any?]  {
               
                resultString.append(dict.jsonString)
                resultString.append(",")
            }
            else if let dict = element.value as? [Any] {
                resultString.append(dict.jsonString)
                resultString.append(",")
            }
            else if let stringValue = element.value as? String {
                
                resultString = resultString.appending("\"").appending(stringValue.escapeSpecialCharacters()).appending("\"")
                resultString.append(",")
            }
            else if let number = element.value as? Int {
                resultString = resultString.appending(String(number))
                resultString.append(",")
            }
            else if let number = element.value as? Double {
                resultString = resultString.appending(String(number))
                resultString.append(",")
            }
            else if let bool = element.value as? Bool {
                resultString = resultString.appending(String(bool))
                resultString.append(",")
            }
            
            
        }
        // das führendes Komma entfernen
        if resultString.count > 1  && self.count > 0 {
            let _  = resultString.removeLast()
        }
        resultString.append("}")
        return resultString
    }
}
extension Array where Element == Any {
    public var jsonString  : String {
        var resultString = "["
       
        self.forEach { element in
            if let textElement = element as? String {
                resultString.append("\"")
                resultString.append(textElement.escapeSpecialCharacters())
                resultString.append("\"")
                resultString.append(",")
            }
            else if let dict = element as? [String: Any?] {
                resultString.append(dict.jsonString)
                resultString.append(",")
            }
            else if let dict = element as? [Any] {
                resultString.append(dict.jsonString)
                resultString.append(",")
            }
            else if let number = element as? Int {
                resultString = resultString.appending(String(number))
                resultString.append(",")
            }
            else if let number = element as? Double {
                resultString = resultString.appending(String(number))
                resultString.append(",")
            }
            else if let bool = element as? Bool {
                resultString = resultString.appending(String(bool))
                resultString.append(",")
            }
            
            
        }
        if resultString.count > 1 && self.count > 0  {
            let _  = resultString.removeLast()
        }
        resultString.append("]")
        return resultString
    }

}
extension Array where Element == JsonArray {
    public var stringValue  : String {
        if let content = self.first {
            return (content as [Any]).jsonString
        }
        else {
            return ""
        }
        
        
        
    }
   
}

