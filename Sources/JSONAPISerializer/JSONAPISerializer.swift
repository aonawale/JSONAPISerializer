import JSON

public class JSONAPISerializer {
    static let version = "1.0"

    public enum Error: Swift.Error {
        case missing(idKey: String, in: Node, config: JSONAPIConfig)
        case invalid(json: Node, config: JSONAPIConfig)
    }

    /// The configuration used when serializing objects
    let config: JSONAPIConfig

    public init(config: JSONAPIConfig) {
        self.config = config
    }

    /// Invoke this method with an array of objects conforming to `JSONRepresentable`s
    /// protocol to get a JSONAPI compliant `JSON` representation of the objects.
    /// - Parameters:
    ///     - objects: An array of `JSONRepresentable` objects to serialize.
    ///     - options: An optional metadata of the serialized objects.
    /// - Throws: `JSONAPISerializer.Error.missingID` if one of the objects
    ///     does not have an `id` with the specified `id` key in the config.
    ///     It throws `JSONAPISerializer.Error.invalidJSON` if the objects
    ///     cannot be represented as a JSON.
    /// - Returns: A JSONAPI compliant structure of the objects.
    public func serialize(_ objects: [JSONRepresentable], options: JSON? = nil) throws -> JSON {
        let serialized = try objects.map { try serialize(object: $0) }
        let included = try objects.map { try serialize(included: $0) }.flatMap { $0.array }.flatMap { $0 }
        return try build(data: Node(serialized), options: options, included: Node(included))
    }

    /// Invoke this method with an object that conforms `JSONRepresentable` to get a
    /// JSONAPI compliant `JSON` representation of the object.
    /// - Parameters:
    ///     - objects: The object to serialize.
    ///     - options: An optional metadata of the serialized object.
    /// - Throws: `JSONAPISerializer.Error.missingID` if the `JSONRepresentable`
    ///     does not have an `id` with the specified `id` key in the config.
    ///     It throws `JSONAPISerializer.Error.invalidJSON` if the object
    ///     cannot be represented as a JSON.
    /// - Returns: A JSONAPI compliant structure of the object.
    public func serialize(_ object: JSONRepresentable, options: JSON? = nil) throws -> JSON {
        let serialized = try serialize(object: object)
        let included = try serialize(included: object)
        return try build(data: serialized, options: options, included: included)
    }

    private func serialize(object: JSONRepresentable) throws -> Node {
        let node = try object.makeJSON().makeNode(in: nil)
        return try serialize(node: node, config: config)
    }

    private func build(data: Node, options: JSON?, included: Node? = nil) throws -> JSON {
        var json = try JSON(node: [
            "data": data,
            "meta": options ?? config.topLevelMeta,
            "links": config.topLevelLinks,
            "jsonapi": Node(node: ["version": JSONAPISerializer.version])
        ])
        if let included = included {
            json["included"] = JSON(included)
        }
        return json
    }

    private func serialize(included object: JSONRepresentable) throws -> Node {
        let node = try object.makeJSON().makeNode(in: nil)
        var included = [Node]()
        try serialize(included: node, config: config, included: &included)
        return Node(included)
    }

    private func serialize(included data: Node, config: JSONAPIConfig, included: inout [Node]) throws {
        guard let object = data.pathIndexableObject else {
            throw Error.invalid(json: data, config: config)
        }

        for (key, value) in object where config.relationships[key] != nil && !config.blacklist.contains(key) {
            let relationConfig = config.relationships[key]!

            if let _ = value.pathIndexableObject {
                let relation = try serialize(node: value, config: relationConfig)
                included.append(relation)
                try serialize(included: value, config: relationConfig, included: &included)
            } else if let array = value.pathIndexableArray {
                try array.forEach {
                    try serialize(included: Node([key: $0]), config: config, included: &included)
                }
            }
        }
    }

    private func serialize(relationship: Node, config: JSONAPIConfig) throws -> Node {
        guard let id = relationship[config.id] else {
            throw Error.missing(idKey: config.id, in: relationship, config: config)
        }
        return try Node(node: [
            "id": id,
            "type": config.type
        ])
    }

    private func serialize(node: Node, config: JSONAPIConfig) throws -> Node {
        guard let object = node.pathIndexableObject else {
            throw Error.invalid(json: node, config: config)
        }
        guard let id = object[config.id] else {
            throw Error.missing(idKey: config.id, in: node, config: config)
        }

        var attributes = Node([:])
        var relationships = Node([:])

        for (key, value) in object where key != config.id && !config.blacklist.contains(key) {

            if let config = config.relationships[key] {
                let relationKey = config.key ?? key
                if let object = value.pathIndexableObject {
                    let data = try serialize(relationship: Node(object), config: config)
                    relationships[relationKey] = Node(["data": data])
                } else if let array = value.pathIndexableArray {
                    let data = try Node(array.map { try serialize(relationship: $0, config: config) })
                    relationships[relationKey] = Node(["data": data])
                } else if let id = value.string {
                    let data = try serialize(relationship: Node(["id": .string(id)]), config: config)
                    relationships[relationKey] = Node(["data": data])
                }
                continue
            }

            if !config.whitelist.isEmpty {
                if config.whitelist.contains(key) {
                    attributes[key] = value
                }
                continue
            }

            attributes[key] = value
        }

        return try Node(node: [
            "id": id,
            "type": config.type,
            "attributes": attributes,
            "relationships": relationships
        ])
    }
}
