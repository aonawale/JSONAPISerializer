import Vapor

open class JSONAPISerializer {
    public enum Error: Swift.Error {
        case invalidJSON
        case missingID
    }

    let config: JSONAPIConfig

    public init(config: JSONAPIConfig) {
        self.config = config
    }

    public func serialize<T: Model>(_ models: [T], type: Model.Type = T.self, options: JSON? = nil) throws -> JSON {
        let result = try models.map { try serializeModel($0) }
        let included = try models.map { try serializeRelationships($0) }.flatMap { $0.nodeArray }.flatMap { $0 }
        return try build(data: Node(result), options: options, included: Node(included))
    }

    public func serialize<T: Model>(_ model: T, type: Model.Type = T.self, options: JSON? = nil) throws -> JSON {
        let data = try serializeModel(model)
        let included = try serializeRelationships(model)
        return try build(data: data, options: options, included: included)
    }

    func build(data: Node, options: JSON?, included: Node? = nil) throws -> JSON {
        var json = try JSON(node: [
            "data": data,
            "meta": options ?? config.topLevelMeta,
            "links": config.topLevelLinks,
            "jsonapi": Node(["version": "1.0"])
        ])
        if let included = included {
            json["included"] = JSON(included)
        }
        return json
    }

    func serializeRelationships(_ model: Model) throws -> Node {
        let node = try model.makeJSON().makeNode()

        var included = [Node]()

        try serializeRelationship(node, config: config, included: &included)

        return Node(included)
    }

    func serializeRelationship(_ node: Node, config: JSONAPIConfig, included: inout [Node]) throws {
        guard let object = node.pathIndexableObject else {
            throw Error.invalidJSON
        }

        for (key, value) in object where config.relationships[key] != nil {
            let _config = config.relationships[key]!

            if let _ = value.pathIndexableObject {
                let relation = try serializeNode(value, config: _config)
                included.append(relation)
                try serializeRelationship(value, config: _config, included: &included)
            } else if let array = value.pathIndexableArray {
                try array.forEach {
                    try serializeRelationship(Node([key: $0]), config: config, included: &included)
                }
            }
        }
    }

    func serializeModel(_ model: Model) throws -> Node {
        let node = try model.makeJSON().makeNode()
        return try serializeNode(node, config: config)
    }

    func serializeNode(_ node: Node, config: JSONAPIConfig) throws -> Node {
        guard let object = node.pathIndexableObject else {
            throw Error.invalidJSON
        }

        guard let id = object[config.id] else {
            throw Error.missingID
        }

        var attrs = Node([:])

        for (key, value) in object where key != config.id {
            if config.blacklist.contains(key) || (config.relationships[key] != nil) {
                continue
            }
            if !config.whitelist.isEmpty && config.whitelist.contains(key) {
                attrs[key] = value
                continue
            }
            attrs[key] = value
        }

        return try Node(node: [
            "id": id,
            "type": config.type,
            "attributes": attrs
        ])
    }
}
