//
//  SwiftyMonacoConfig.swift
//  SwiftyMonaco
//
//  Created by Patric Dubois on 19.03.26.
//


public struct SwiftyMonacoConfig {
    public var syntax: SyntaxHighlight?
    public var minimap: Bool = true
    public var scrollbar: Bool = true
    public var smoothCursor: Bool = false
    public var updatedText : String?
    public  var cursorBlink: CursorBlink = .blink
    public  var fontSize: Int = 12
    public  var monacoLanguage : LanguageSupport? = nil
    public  var theme: Theme? = nil
    public  var customLanguageSpecs: [LanguageSupport: String] = [:]
    public  var markers: [EditorMarker] = []
    public init(minimap: Bool, scrollbar: Bool, smoothCursor: Bool, cursorBlink: CursorBlink, fontSize: Int, monacoLanguage: LanguageSupport? = nil, theme: Theme? = nil, customLanguageSpecs: [LanguageSupport: String] = [:], markers: [EditorMarker] = []) {

        self.minimap = minimap
        self.scrollbar = scrollbar
        self.smoothCursor = smoothCursor
        self.cursorBlink = cursorBlink
        self.fontSize = fontSize
        self.monacoLanguage = monacoLanguage
        self.theme = theme
        self.customLanguageSpecs = customLanguageSpecs
        self.markers = markers
    }
    public init() {
        
    }
}
