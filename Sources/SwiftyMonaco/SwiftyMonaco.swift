//
//  SwiftyMonaco.swift
//
//
//  Created by Pavel Kasila on 20.03.21.
//

import SwiftUI

#if os(macOS)
typealias ViewControllerRepresentable = NSViewControllerRepresentable
#else
typealias ViewControllerRepresentable = UIViewControllerRepresentable
#endif


public struct SwiftyMonaco: ViewControllerRepresentable, MonacoViewControllerDelegate {
   
    
    
    
    var id = UUID()
    
    var languageSupport : Binding<[LanguageSupport]>?
    var text: Binding<String>
    var isDirty: Binding<Bool>
    var config : SwiftyMonacoConfig
    
    
    public init(text: Binding<String>, isDirty : Binding<Bool>, config: SwiftyMonacoConfig, languageSupport: Binding<[LanguageSupport]>) {
        self.text = text
        self.isDirty = isDirty
        self.config = config
        self.languageSupport = languageSupport
    }
    
    #if os(macOS)
    public func makeNSViewController(context: Context) -> MonacoViewController {
        let vc = MonacoViewController()
        vc.delegate = self
        return vc
    }
    
    public func updateNSViewController(_ nsViewController: MonacoViewController, context: Context) {
        nsViewController.delegate = self
        nsViewController.registerCustomLanguages()
        nsViewController.updateLanguage()
        nsViewController.updateText()
        nsViewController.updateMarkers()
    }
    #endif
    
    #if os(iOS)
    public func makeUIViewController(context: Context) -> MonacoViewController {
        let vc = MonacoViewController()
        vc.delegate = self
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: MonacoViewController, context: Context) {
        
    }
    #endif
    
    public func monacoView(readText controller: MonacoViewController) -> String {
        return self.text.wrappedValue
    }
    
    public func monacoView(controller: MonacoViewController, textDidChange text: String) {
        self.text.wrappedValue = text
        self.isDirty.wrappedValue = true
    }
    
    public func monacoView(getSyntax controller: MonacoViewController) -> SyntaxHighlight? {
        return config.syntax
    }
    
    public func monacoView(getMinimap controller: MonacoViewController) -> Bool {
        return config.minimap
    }
    
    public func monacoView(getScrollbar controller: MonacoViewController) -> Bool {
        return config.scrollbar
    }
    
    public func monacoView(getSmoothCursor controller: MonacoViewController) -> Bool {
        return config.smoothCursor
    }
    
    public func monacoView(getCursorBlink controller: MonacoViewController) -> CursorBlink {
        return config.cursorBlink
    }
    
    public func monacoView(getFontSize controller: MonacoViewController) -> Int {
        return config.fontSize
    }
    
    public func monacoView(getTheme controller: MonacoViewController) -> Theme? {
        return config.theme
    }
    public func monacoView(getLanguageSupport controller: MonacoViewController) -> LanguageSupport? {
        return config.monacoLanguage
    }
    public func monacoView(getCustomLanguageSpecs controller: MonacoViewController) -> [LanguageSupport: String] {
        return config.customLanguageSpecs
    }
    public func monacoView(getMarkers controller: MonacoViewController) -> [EditorMarker] {
        return config.markers
    }
    public mutating func monacoView(updateLanguageSupport: [LanguageSupport], controller: MonacoViewController) {
        self.languageSupport?.wrappedValue = updateLanguageSupport
    }
    
}

// MARK: - Modifiers
public extension SwiftyMonaco {
    func syntaxHighlight(_ syntax: SyntaxHighlight) -> Self {
        var m = self
        m.config.syntax = syntax
        return m
    }
}

public extension SwiftyMonaco {
    func minimap(_ enabled: Bool) -> Self {
        var m = self
        m.config.minimap = enabled
        return m
    }
}

public extension SwiftyMonaco {
    func scrollbar(_ enabled: Bool) -> Self {
        var m = self
        m.config.scrollbar = enabled
        return m
    }
}

public extension SwiftyMonaco {
    func smoothCursor(_ enabled: Bool) -> Self {
        var m = self
        m.config.smoothCursor = enabled
        return m
    }
}

public extension SwiftyMonaco {
    func cursorBlink(_ style: CursorBlink) -> Self {
        var m = self
        m.config.cursorBlink = style
        return m
    }
}

public extension SwiftyMonaco {
    func fontSize(_ size: Int) -> Self {
        var m = self
        m.config.fontSize = size
        return m
    }
}

public extension SwiftyMonaco {
    func theme(_ theme: Theme) -> Self {
        var m = self
        m.config.theme = theme
        return m
    }
}
