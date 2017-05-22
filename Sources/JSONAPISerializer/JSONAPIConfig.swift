import JSON

public struct JSONAPIConfig {
    let id: String
    let type: String
    let whitelist: [String]
    let blacklist: [String]
    let relationships: [String: JSONAPIConfig]
    let topLevelLinks: JSON
    let linksFor: (_ object: Object) -> JSON
    let topLevelMeta: JSON

    public init(
        id: String = "id",
        type: String,
        whitelist: [String] = [],
        blacklist: [String] = [],
        relationships: [String: JSONAPIConfig] = [:],
        linksFor: ((_ object: Object) -> JSON)? = nil,
        topLevelLinks: JSON? = nil,
        topLevelMeta: JSON = JSON(Node([:]))
    ) {
        self.id = id
        self.type = type
        self.whitelist = whitelist
        self.blacklist = blacklist
        self.relationships = relationships

        self.topLevelLinks = topLevelLinks ?? JSON(Node(["self": Node("/\(type)")]))
        self.linksFor = linksFor ?? {
            return JSON(Node("/\(type)/\($0.id ?? "")"))
        }
        self.topLevelMeta = topLevelMeta
    }
}
