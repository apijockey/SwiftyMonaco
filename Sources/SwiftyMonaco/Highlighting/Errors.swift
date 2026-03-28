//
//  Errors.swift
//  SwiftyMonaco
//
//  Created by Patric Dubois on 17.03.26.
//

import Foundation
enum Errors : LocalizedError {
    case noWebView,
         unsupportedType,
        noURL,
        javascriptEvaluationFailed(String),
         webViewNotAvailable,
        unsupportedJavascriptReturnType
    var errorDescription: String? {
        switch self {
        case .noWebView:
            return "No webview found"
        case .unsupportedType:
            return "Unsupported type (supported types are: Array, Bool, Dictionary, Double, Data(UTF8), Date, String, URL)"
        case .noURL:
            return "No URL set for HTMLTeststep"
        case .webViewNotAvailable:
            return "Webview not initialized, please file a bug"
        case .unsupportedJavascriptReturnType:
            return "Unsupported type (supported types are: Array, Bool, Dictionary, Double, Data(UTF8), Date, String, URL  )"
        case .javascriptEvaluationFailed(let message):
            return "JavaScript evaluation failed: \(message)"
        }
    }
}
