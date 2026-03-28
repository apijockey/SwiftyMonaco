//
//  MonacoViewController.swift
//  
//
//  Created by Pavel Kasila on 20.03.21.
//

#if os(macOS)
import AppKit
public typealias ViewController = NSViewController
#else
import UIKit
public typealias ViewController = UIViewController
#endif
import WebKit
import OSLog
public class MonacoViewController: ViewController, WKUIDelegate, WKNavigationDelegate {
    var logger =  Logger(subsystem: "MonacViewController", category: "SwiftyMonaco")
    var delegate: MonacoViewControllerDelegate?
    var supportedLanguages : [LanguageSupport] = []
    var webView: WKWebView!
    private(set) var isEditorReady = false
    private var appliedLanguageId: String? = nil
    /// Tracks the last text value known to Monaco, to avoid pushing text back when Monaco itself triggered the change.
    var lastTextFromMonaco: String = ""
    /// Prevents duplicate in-flight JS calls when updateNSViewController fires multiple times before the async JS completes.
    private var pendingTextUpdate: String? = nil
    private var customLanguagesRegistered = false

  
    
    public override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(UpdateTextScriptHandler(self), name: "updateText")
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        #if os(iOS)
        webView.backgroundColor = .none
        #else
        webView.layer?.backgroundColor = NSColor.clear.cgColor
        #endif
        view = webView
        #if os(macOS)
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(sender:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
        #endif
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMonaco()
       
    }
    
    private func loadMonaco() {
        let myURL = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "_Resources")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    public func updateLanguage() {
        guard let languageSupport = self.delegate?.monacoView(getLanguageSupport: self) else { return }
        let languageId = languageSupport.id
        guard languageId != appliedLanguageId else { return }
        guard isEditorReady else { return }

        let javascript = """
        (function(){
            if (typeof editor !== 'undefined' && editor.editor) {
                editor.addAction(function(monaco, editorInstance) {
                    var model = editorInstance.getModel();
                    if (model) {
                        monaco.editor.setModelLanguage(model, '\(languageId)');
                    }
                });
                return true;
            }
            return false;
        })()
        """
        webView.evaluateJavaScript(javascript, in: nil, in: .page) { [weak self] result in
            if case .success(let value) = result, value as? Bool == true {
                self?.appliedLanguageId = languageId
            }
            if case .failure(let error) = result {
                self?.logger.error("Failed to update language \(error.localizedDescription)")
            }
        }
    }
    public func registerCustomLanguages() {
        guard isEditorReady, !customLanguagesRegistered else { return }
        let specs = self.delegate?.monacoView(getCustomLanguageSpecs: self) ?? [:]
        guard !specs.isEmpty else {
            customLanguagesRegistered = true
            return
        }
       
        
        let registrationJS = specs.map { (languageSupport, spec) in
            let encodedLanguageSupport = languageSupport.encoded
            return """
            (function() {
                var existingLangs = monaco.languages.getLanguages();
                var alreadyRegistered = existingLangs.some(function(l) { return l.id === '\(languageSupport.id)'; });
                if (!alreadyRegistered) {
                    monaco.languages.register(\(encodedLanguageSupport)); 
                    monaco.languages.setMonarchTokensProvider('\(languageSupport.id)', \(spec));
                }
            })();
            """
        }.joined(separator: "\n")
        ////{ id: '\(languageId)' }
        let javascript = """
        (function(){
            if (typeof editor !== 'undefined' && editor.editor) {
                editor.addAction(function(monaco, editorInstance) {
                    \(registrationJS)
                });
                return true;
            }
            return false;
        })()
        """
        webView.evaluateJavaScript(javascript, in: nil, in: .page) { [weak self] result in
            if case .success(let value) = result, value as? Bool == true {
                self?.customLanguagesRegistered = true
                self?.updateLanguages()
            }
            if case .failure(let error) = result {
                self?.logger.error("registerCustomLanguages failed: \(error.localizedDescription)")
            }
        }
    }
    public func updateText() {
        
        guard isEditorReady else { return }
        let newText = self.delegate?.monacoView(readText: self) ?? ""
        
        guard newText != lastTextFromMonaco else { return }
        
        guard pendingTextUpdate != newText else { return }
        pendingTextUpdate = newText
        let b64 = newText.data(using: .utf8)?.base64EncodedString() ?? ""
        let javascript = """
        (function(){
            if (typeof editor !== 'undefined' && editor.editor) {
                editor.setText(atob('\(b64)'));
                return true;
            }
            return false;
        })()
        """
        webView.evaluateJavaScript(javascript, in: nil, in: .page) { [weak self, newText] result in
            self?.pendingTextUpdate = nil
            switch result {
            case .success(let value):
                if value as? Bool == true {
                    self?.lastTextFromMonaco = newText
        
                } else {
        
                }
            case .failure(let error):
                self?.logger.error("SwiftyMonaco: updateText JS failed: \(error.localizedDescription)")
            }
        }
    }
    public func updateMarkers() {
        guard isEditorReady else { return }
        let markers = self.delegate?.monacoView(getMarkers: self) ?? []

        let markersJS = markers.map { marker -> String in
            let severityValue = marker.severity == .error ? 8 : 4
            let startLine = max(1, marker.startLine)
            let endLine = max(startLine, marker.endLine)
            let escapedMessage = marker.message
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "")
            return "{ severity: \(severityValue), startLineNumber: \(startLine), startColumn: 1, endLineNumber: \(endLine), endColumn: 10000, message: '\(escapedMessage)' }"
        }.joined(separator: ",")

        let javascript = """
        (function(){
            if (typeof editor !== 'undefined' && editor.editor) {
                editor.addAction(function(monaco, editorInstance) {
                    var model = editorInstance.getModel();
                    if (model) {
                        monaco.editor.setModelMarkers(model, 'validation', [\(markersJS)]);
                    }
                });
                return true;
            }
            return false;
        })()
        """
        webView.evaluateJavaScript(javascript, in: nil, in: .page) { result in
           
            switch result {
            case .success:
                return
            case .failure(let error):
                self.logger.error("Failed to update markers: \(error.localizedDescription)")
            }
        }
    }
    public func updateLanguages() {
        
            Task {
                
                    
                
                let result = await readWithJavaScript(string: LanguageSupportList.javascript)
                switch result {
                case .failure(let error):
                    handleError(javascript: LanguageSupportList.javascript, message: error.localizedDescription)
                  break
                case .success(let result):
                    guard let data = result.data(using: .utf8) else {
                        handleError(javascript: LanguageSupportList.javascript, message: "invalid UTF-8 String for response")
                        break
                    }
                    let jsonDecoder = JSONDecoder()
                    do {
                        let monacoLanguages = try jsonDecoder.decode([LanguageSupport].self, from: data)
                        self.supportedLanguages = monacoLanguages
                        self.delegate?.monacoView(updateLanguageSupport: self.supportedLanguages, controller: self)
                    }
                    catch {
                        handleError(javascript: LanguageSupportList.javascript, message: "Failed to decode JSON: \(error.localizedDescription)")
                    }
                    
                }
            }
        
    }
    // MARK: - Dark Mode
    private func updateTheme() {
        evaluateJavascript("""
        (function(){
            monaco.editor.setTheme('\(detectTheme())')
        })()
        """)
    }
    
    #if os(macOS)
    @objc private func interfaceModeChanged(sender: NSNotification) {
        updateTheme()
    }
    #else
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTheme()
    }
    #endif
    
    private func detectTheme() -> String {
        #if os(macOS)
        if UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" {
            return "vs-dark"
        } else {
            return "vs"
        }
        #else
        switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return "vs"
            case .dark:
                return "vs-dark"
            @unknown default:
                return "vs"
        }
        #endif
    }
    private func handleError(javascript : String, message : String) {
        #if os(macOS)
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = "Something went wrong while evaluating \(message): \(javascript)"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
        #else
        let alert = UIAlertController(title: "Error", message: "Something went wrong while evaluating \(message): \(javascript)", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        #endif
    }
    
    // MARK: - WKWebView
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
       
        updateLanguages()
       
        // Syntax Highlighting
        //let syntax = self.delegate?.monacoView(getSyntax: self)
        var theme = detectTheme()
        
        if let _theme = self.delegate?.monacoView(getTheme: self) {
            switch _theme {
            case .light:
                theme = "vs"
            case .dark:
                theme = "vs-dark"
            }
        }
        var syntax = ""
        if let languageSupport = self.delegate?.monacoView(getLanguageSupport: self) {
            
            syntax = "language: '\(languageSupport.id)',"
        }
        
        // Minimap
        let _minimap = self.delegate?.monacoView(getMinimap: self)
        let minimap = "minimap: { enabled: \(_minimap ?? true) }"
        
        // Scrollbar
        let _scrollbar = self.delegate?.monacoView(getScrollbar: self)
        let scrollbar = "scrollbar: { vertical: \(_scrollbar ?? true ? "\"visible\"" : "\"hidden\"") }"
        
        // Smooth Cursor
        let _smoothCursor = self.delegate?.monacoView(getSmoothCursor: self)
        let smoothCursor = "cursorSmoothCaretAnimation: \(_smoothCursor ?? false)"
        
        // Cursor Blinking
        let _cursorBlink = self.delegate?.monacoView(getCursorBlink: self)
        let cursorBlink = "cursorBlinking: \"\(_cursorBlink ?? .blink)\""
        
        // Font size
        let _fontSize = self.delegate?.monacoView(getFontSize: self)
        let fontSize = "fontSize: \(_fontSize ?? 12)"
        
       
        
        
        // Code itself
        let text = self.delegate?.monacoView(readText: self) ?? ""
        let b64 = text.data(using: .utf8)?.base64EncodedString()
        let javascript =
        """
        (function() {
        \(syntax)

        editor.create({value: atob('\(b64 ?? "")'), 
            automaticLayout: true, 
            theme: "\(theme)",
            \(syntax)
            \(minimap),
            \(scrollbar), 
            \(smoothCursor), 
            \(cursorBlink), 
            \(fontSize)});
        var meta = document.createElement('meta'); 
        meta.setAttribute('name', 'viewport'); 
        meta.setAttribute('content', 'width=device-width'); 
        document.getElementsByTagName('head')[0].appendChild(meta);
        return true;
        })();
        """
        webView.evaluateJavaScript(javascript, in: nil, in: .page) { [weak self] result in
            switch result {
            case .success:
                self?.isEditorReady = true
                self?.lastTextFromMonaco = text
                self?.registerCustomLanguages()
                self?.updateLanguage()
            case .failure(let error):
                self?.logger.error("Monaco editor initialization failed: \(error.localizedDescription)")
            }
        }
    }

    private func evaluateJavascript(_ javascript: String) {
        webView.evaluateJavaScript(javascript, in: nil, in: WKContentWorld.page) {
          result in
          switch result {
          case .failure(let error):
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Something went wrong while evaluating \(error.localizedDescription): \(javascript)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
            #else
            let alert = UIAlertController(title: "Error", message: "Something went wrong while evaluating \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            #endif
            break
          case .success(_):
            
            break
          }
        }
    }
    private func readWithJavaScript(string javaScriptString: String) async -> Result<String,Errors>{
        
       
        do {
            let value = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any?, Error>) in
                webView.evaluateJavaScript(javaScriptString) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    } else {
                        continuation.resume(returning: result)
                        return
                    }
                }
            }
            let javascriptResult = await JavascriptStringResult(positiveFormat: nil, dateFormatting: nil).javascriptAnyToString(javascriptResult: value)
            switch javascriptResult {
            case .success(let success):
                return .success(success)
            case .failure(let failure):
                return .failure(.javascriptEvaluationFailed(failure.localizedDescription))
            }
        }
        catch {
            return .failure(.javascriptEvaluationFailed((error as NSError).debugDescription))
        }
    }
}

// MARK: - Handler

private extension MonacoViewController {
    final class UpdateTextScriptHandler: NSObject, WKScriptMessageHandler {
        private var debounceTimer: Timer?
        private var lastValidText: String = "" // Speichert den letzten gültigen Inhalt
        private let parent: MonacoViewController
        
        init(_ parent: MonacoViewController) {
            self.parent = parent
        }
        
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            // 1. Base64-String prüfen
            guard let base64 = message.body as? String, !base64.isEmpty else {
               
                return
            }
            
            // 2. Base64-Padding prüfen und korrigieren
            let paddedBase64 = base64.padding(
                toLength: ((base64.count + 3) / 4) * 4,
                withPad: "=",
                startingAt: 0
            )
            
            // 3. Daten dekodieren
            guard let data = Data(base64Encoded: paddedBase64) else {
               
                return
            }
            
            // 4. UTF-8-String erstellen (mit Fallback)
            if let text = String(data: data, encoding: .utf8) {
                // 5. Debouncing: Timer zurücksetzen
                debounceTimer?.invalidate()
                debounceTimer = Timer.scheduledTimer(
                    withTimeInterval: 0.5, // 500 ms Verzögerung
                    repeats: false
                ) { _ in
                    DispatchQueue.main.async {
                        self.lastValidText = text // Speichere den gültigen Inhalt
                        self.parent.lastTextFromMonaco = text
                        self.parent.delegate?.monacoView(controller: self.parent, textDidChange: self.lastValidText)
                    }
                }
            } else {
               
                // Optional: Letzten gültigen Inhalt erneut senden
                DispatchQueue.main.async {
                    if !self.lastValidText.isEmpty {
                        self.parent.delegate?.monacoView(controller: self.parent, textDidChange: self.lastValidText)
                    }
                }
            }
        }
    }
}

// MARK: - Delegate

public protocol MonacoViewControllerDelegate {
    func monacoView(readText controller: MonacoViewController) -> String
    func monacoView(getSyntax controller: MonacoViewController) -> SyntaxHighlight?
    func monacoView(getMinimap controller: MonacoViewController) -> Bool
    func monacoView(getScrollbar controller: MonacoViewController) -> Bool
    func monacoView(getSmoothCursor controller: MonacoViewController) -> Bool
    func monacoView(getCursorBlink controller: MonacoViewController) -> CursorBlink
    func monacoView(getFontSize controller: MonacoViewController) -> Int
    func monacoView(getTheme controller: MonacoViewController) -> Theme?
    func monacoView(controller: MonacoViewController, textDidChange: String)
    func monacoView(getLanguageSupport controller: MonacoViewController) -> LanguageSupport?
    func monacoView(getCustomLanguageSpecs controller: MonacoViewController) -> [LanguageSupport: String]
    func monacoView(getMarkers controller: MonacoViewController) -> [EditorMarker]
    mutating func monacoView(updateLanguageSupport : [LanguageSupport],controller: MonacoViewController)
}
