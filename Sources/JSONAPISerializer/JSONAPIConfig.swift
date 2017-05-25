import JSON

public struct JSONAPIConfig {
    let id: String
    let type: String
    let whitelist: [String]
    let blacklist: [String]
    let relationships: [String: JSONAPIConfig]
    let topLevelLinks: JSON
    let linksFor: ((_ object: JSONRepresentable) -> JSON)?
    let topLevelMeta: JSON

    public init(
        type: String,
        id: String = "id",
        whitelist: [String] = [],
        blacklist: [String] = [],
        relationships: [String: JSONAPIConfig] = [:],
        linksFor: ((_ object: JSONRepresentable) -> JSON)? = nil,
        topLevelLinks: JSON? = nil,
        topLevelMeta: JSON = JSON(Node([:]))
    ) {
        self.id = id
        self.type = type
        self.whitelist = whitelist
        self.blacklist = blacklist
        self.relationships = relationships

        self.topLevelLinks = topLevelLinks ?? JSON(Node(["self": Node("/\(type)")]))
        self.linksFor = linksFor
        self.topLevelMeta = topLevelMeta
    }
}
