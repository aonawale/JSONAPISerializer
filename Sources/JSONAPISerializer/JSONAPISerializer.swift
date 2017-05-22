import JSON

public protocol Object: JSONRepresentable {
    var id: Node? { get set }
}

public class JSONAPISerializer {
    static let version = "1.0"
    
    public enum Error: Swift.Error {
        case missingID
        case invalidJSON
    }
    
    /// The configuration used when serializing objects
    let config: JSONAPIConfig

    public init(config: JSONAPIConfig) {
        self.config = config
    }
    
    /// Invoke this method with an array of `Object`s to get a
    /// JSONAPI compliant `JSON` representation of the objects.
    /// - Parameters:
    ///     - objects: An array of `Object` to serialize.
    ///     - options: The metadata of the serialized objects.
    /// - Throws: `JSONAPISerializer.Error.missingID` if one of the `Object`s
    ///     does not have an `id` with the specified `id` key in the config.
    ///     It throws `JSONAPISerializer.Error.invalidJSON` if the objects
    ///     cannot be represented as a JSON.
    /// - Returns: A JSONAPI compliant structure of the objects.
    public func serialize(_ objects: [Object], options: JSON? = nil) throws -> JSON {
        let serialized = try objects.map { try serialize(object: $0) }
        let included = try objects.map { try serialize(included: $0) }.flatMap { $0.array }.flatMap { $0 }
        return try build(node: Node(serialized), options: options, included: Node(included))
    }

    /// Invoke this method with an `Object` to get a
    /// JSONAPI compliant `JSON` representation of the object.
    /// - Parameters:
    ///     - objects: The `Object` to serialize.
    ///     - options: The metadata of the serialized object.
    /// - Throws: `JSONAPISerializer.Error.missingID` if the `Object`
    ///     does not have an `id` with the specified `id` key in the config.
    ///     It throws `JSONAPISerializer.Error.invalidJSON` if the object
    ///     cannot be represented as a JSON.
    /// - Returns: A JSONAPI compliant structure of the object.
    public func serialize(_ object: Object, options: JSON? = nil) throws -> JSON {
        let serialized = try serialize(object: object)
        let included = try serialize(included: object)
        return try build(node: serialized, options: options, included: included)
    }
    
    private func serialize(object: Object) throws -> Node {
        let node = try object.makeJSON().makeNode(in: nil)
        return try serialize(node: node, config: config)
    }

    private func build(node: Node, options: JSON?, included: Node? = nil) throws -> JSON {
        var json = try JSON(node: [
            "data": node,
            "meta": options ?? config.topLevelMeta,
            "links": config.topLevelLinks,
            "jsonapi": Node(node: ["version": JSONAPISerializer.version])
        ])
        if let included = included {
            json["included"] = JSON(included)
        }
        return json
    }
    
    private func serialize(included object: Object) throws -> Node {
        let node = try object.makeJSON().makeNode(in: nil)
        var included = [Node]()
        try serialize(included: node, config: config, included: &included)
        return Node(included)
    }

    private func serialize(included node: Node, config: JSONAPIConfig, included: inout [Node]) throws {
        guard let object = node.pathIndexableObject else {
            throw Error.invalidJSON
        }

        for (key, value) in object where config.relationships[key] != nil {
            let _config = config.relationships[key]!

            if let _ = value.pathIndexableObject {
                let relation = try serialize(node: value, config: _config)
                included.append(relation)
                try serialize(included: value, config: _config, included: &included)
            } else if let array = value.pathIndexableArray {
                try array.forEach {
                    try serialize(included: Node([key: $0]), config: config, included: &included)
                }
            }
        }
    }

    private func serialize(relationship: Node, config: JSONAPIConfig) throws -> Node {
        guard let id = relationship[config.id] else {
            throw Error.missingID
        }
        return try Node(node: [
            "id": id,
            "type": config.type
        ])
    }

    private func serialize(node: Node, config: JSONAPIConfig) throws -> Node {
        guard let object = node.pathIndexableObject else {
            throw Error.invalidJSON
        }
        
        guard let id = object[config.id] else {
            throw Error.missingID
        }
        
        var attrs = Node([:])
        var relationships = Node([:])
        
        for (key, value) in object where key != config.id {
            if config.blacklist.contains(key) {
                continue
            }
            
            if let relation = config.relationships[key] {
                if let object = value.pathIndexableObject {
                    let data = try serialize(relationship: Node(object), config: relation)
                    relationships[key] = Node(["data": data])
                } else if let array = value.pathIndexableArray {
                    let data = try Node(array.map { try serialize(relationship: $0, config: config) })
                    relationships[key] = Node(["data": data])
                }
                continue
            }
            
            if !config.whitelist.isEmpty {
                if config.whitelist.contains(key) {
                    attrs[key] = value
                }
                continue
            }
            
            attrs[key] = value
        }
        
        return try Node(node: [
            "id": id,
            "type": config.type,
            "attributes": attrs,
            "relationships": relationships
        ])
    }
}
