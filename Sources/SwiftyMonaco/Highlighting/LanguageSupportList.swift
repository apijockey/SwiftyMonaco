//
//  MonacoLanguages.swift
//  SwiftyMonaco
//
//  Created by Patric Dubois on 17.03.26.
//
import Foundation


/// LanguageSupportList
/// The Monaco editor comes with a list of predefined languages (support for code completions and syntax highlighting.
///  The SwiftyMonaco package comes with an additional list of predefined languages, which supports custom syntax highlighting
///  Adopters of this package may include further Language support.
///  Each of the three may override the definitions of the other.
///  The flags on this struct define how definitions are composed to hold a unique list of LanguageSupport definitions.
///  Predefined settings:
///  - include all monaco editor definitions as their support is proven.
///  - SwiftyMonaco-predefined-Settings are not taken into account as they have no additional functionality and serve more as an example
///  - Custom LanguageSupport will override Monaco language support which means, when you define a Monarch definition, it will be registered with the Monaco editor and override  an existing definition.
public struct LanguageSupportList : Codable {
    
    
    public static let javascript = """
    
        var languages = monaco.languages.getLanguages();
        var monacoLanguages = [];
        for (var i = 0;i<languages.length;i++) {
          const {id, aliases, mimetypes, extensions} = languages[i];
           const language =  {id, aliases, mimetypes, extensions};
           //console.log(language);
          monacoLanguages.push(language);
        }
        monacoLanguages;
    
    """
    var languages : [LanguageSupport]
    
    
}
public struct LanguageSupport  : Identifiable,Hashable, Codable, Comparable{
    public static func < (lhs: LanguageSupport, rhs: LanguageSupport) -> Bool {
        lhs.id < rhs.id
    }
    
    public static func == (lhs: LanguageSupport, rhs: LanguageSupport) -> Bool {
        return lhs.id == rhs.id
    }
    public init(id: String, extensions: [String]?, aliases: [String]?, mimeTypes: [String]?) {
        self.id = id
        self.extensions = extensions
        self.aliases = aliases
        self.mimeTypes = mimeTypes
    
    }   
    public let id : String
    public let extensions : [String]?
    public let aliases: [String]?
    public let mimeTypes: [String]?
    
    public var encoded : String {
        do {
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(self)
            let text =  String(data:data, encoding: .utf8) ?? ""
            return text
        }
        catch {
            
            return ""
        }
    }
    
}
