//
//  JavascriptStringResult.swift
//  SwiftyMonaco
//
//  Created by Patric Dubois on 17.03.26.
//  from the Sextant-Project
//


//
//  JavascriptStringResult.swift
//  APIJockey TEST
//
//  Created by Patric Dubois on 03.10.25.
//

import Foundation
public struct JavascriptStringResult {
 
    
    let positiveFormat : String?
    let dateFormatting : String?
    enum Errors : LocalizedError {
        case unsupportedType
        var errorDescription: String? {
            switch self {
            case .unsupportedType:
                return "Unsupported type (supported types are: Array, Bool, Dictionary, Double, Data(UTF8), Date, String, URL)"
            }
        }
    }
    func javascriptAnyToString(javascriptResult : Any?) async  -> Result<String,JavascriptStringResult.Errors> {
        
        
            if let javascriptResultAsString = javascriptResult as? String {
                return  .success(javascriptResultAsString)
            }
            else if let javascriptResultAsDouble = javascriptResult as? Double {
                let numberFormatter = NumberFormatter()
                numberFormatter.positiveFormat = self.positiveFormat
                if  let formatting = self.positiveFormat,
                    !formatting.isEmpty {
                    numberFormatter.negativeFormat = "-\(formatting)"
                   
                }
                    return .success(numberFormatter.string(for: javascriptResultAsDouble) ?? String(javascriptResultAsDouble))
            }
            else if let javascriptResultAsBool = javascriptResult as? Bool {
                return  .success(String(javascriptResultAsBool))
            }
            else if let javascriptResultAsArray = javascriptResult as? [Any] {
                return .success(javascriptResultAsArray.jsonString)
            }
            else if let javascriptResultAsDictionary = javascriptResult as? [String: Any?] {
                return .success(javascriptResultAsDictionary.jsonString)
            }
            else if let javascriptResultAsData = javascriptResult as? Data,
                    let text = String(data: javascriptResultAsData, encoding: .utf8){
                return .success(text)
            }
            else if let javascriptResultAsURL = javascriptResult as? URL {
                return .success(javascriptResultAsURL.absoluteString)
            }
            else if let javascriptResultAsDate = javascriptResult as? Date {
                let dateformatter = DateFormatter()
                dateformatter.dateFormat = self.dateFormatting ?? "yyyy-MM-dd HH:mm:ss.SSS"
                return .success(dateformatter.string(from: javascriptResultAsDate))
            }
            else if javascriptResult as? Never  != nil{
                return .failure(Self.Errors.unsupportedType)
            }
            else {
                return .failure(Self.Errors.unsupportedType)
            }
    
    }
    
}
