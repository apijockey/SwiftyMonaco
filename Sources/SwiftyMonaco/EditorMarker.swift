//
//  EditorMarker.swift
//  SwiftyMonaco
//
//  Created by Patric Dubois on 22.03.26.
//

public struct EditorMarker: Equatable {
    public enum Severity: String,Equatable {
        case error, warning
        
    }
    public let severity: Severity
    public let message: String
    public let startLine: Int  // 1-based
    public let endLine: Int    // 1-based

    public init(severity: Severity, message: String, startLine: Int, endLine: Int) {
        self.severity = severity
        self.message = message
        self.startLine = startLine
        self.endLine = endLine
    }
}
