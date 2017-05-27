import JSON
import XCTest
@testable import JSONAPISerializer

class User: JSONRepresentable {
    var id: Node?
    let firstName: String
    let lastName: String
    var profile: Profile?
    var pets: [Pet] = []
    
    init(firstName: String, lastName: String) {
        id = Node.string(UUID().uuidString)
        self.firstName = firstName
        self.lastName = lastName
    }

    func makeJSON() throws -> JSON {
        var json = JSON([:])
        try json.set("id", id)
        try json.set("first-name", firstName)
        try json.set("last-name", lastName)
        try json.set("pets", pets.makeJSON())
        if let profile = profile {
            try json.set("profile", profile.makeJSON())
        }
        return json
    }
}

struct Profile: JSONRepresentable {
    var id: Node?
    let userId: String
    
    init(userId: String) {
        id = Node.string(UUID().uuidString)
        self.userId = userId
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON([:])
        try json.set("profile-id", id)
        try json.set("user-id", userId)
        return json
    }
}

class Pet: JSONRepresentable {
    var id: Node?
    let name: String
    let userId: String
    var toys: [Toy] = []
    
    init(name: String, userId: String) {
        id = Node.string(UUID().uuidString)
        self.name = name
        self.userId = userId
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON([:])
        try json.set("id", id)
        try json.set("name", name)
        try json.set("user-id", userId)
        try json.set("toys", toys.makeJSON())
        return json
    }
}

struct Toy: JSONRepresentable {
    var id: Node?
    let name: String
    let petId: String
    
    init(name: String, petId: String) {
        id = Node.string(UUID().uuidString)
        self.name = name
        self.petId = petId
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON([:])
        try json.set("id", id)
        try json.set("name", name)
        try json.set("pet-id", petId)
        return json
    }
}

class JSONAPISerializerTests: XCTestCase {
    static let allTests = [
        ("testMissingIdError", testMissingIdError),
        ("testToOneRelationship", testToOneRelationship),
        ("testToManyRelationship", testToManyRelationship),
        ("testWhitelist", testWhitelist),
        ("testBlacklist", testBlacklist),
        ("testSerilizeManyObjects", testSerilizeManyObjects),
        ("testSerilizeSingleObject", testSerilizeSingleObject)
    ]
    
    func testMissingIdError() {
        let user = User(firstName: "foo", lastName: "bar")
        let config = JSONAPIConfig(type: "users", id: "uid")
        let serializer = JSONAPISerializer(config: config)
        
        XCTAssertThrowsError(try serializer.serialize(user))
        
        XCTAssertThrowsError(try serializer.serialize(user), "") {
            guard let error = $0 as? JSONAPISerializer.Error else {
                fatalError("Unexpected Error \($0) thrown")
            }
            switch error {
            case .missing(idKey: let id, in: _, config: let config):
                XCTAssertEqual(id, config.id)
            default: break
            }
        }
    }
    
    func testToOneRelationship() throws {
        let user = User(firstName: "foo", lastName: "bar")
        let profile = Profile(userId: user.id!.string!)
        user.profile = profile
        
        let profileConfig = JSONAPIConfig(type: "user-profile", id: "profile-id")
        let userConfig = JSONAPIConfig(type: "users", relationships: ["profile": profileConfig])
        let serializer = JSONAPISerializer(config: userConfig)
        let serialized = try serializer.serialize(user)
        
        XCTAssertNotNil(serialized["data"]?["relationships"]?["profile"])
        XCTAssertEqual(serialized["included"]?[0]?["type"], "user-profile")
        XCTAssertNotNil(serialized["included"]?[0]?["id"])
    }
    
    func testToManyRelationship() throws {
        let user = User(firstName: "foo", lastName: "bar")
        let pet = Pet(name: "pet", userId: user.id!.string!)
        pet.toys = [Toy(name: "toy", petId: pet.id!.string!)]
        user.pets = [pet]
        
        let toysConfig = JSONAPIConfig(type: "toys")
        let petsConfig = JSONAPIConfig(type: "pets", relationships: ["toys": toysConfig])
        let userConfig = JSONAPIConfig(type: "users", relationships: ["pets": petsConfig])
        let serializer = JSONAPISerializer(config: userConfig)
        let serialized = try serializer.serialize(user)
        
        XCTAssertNil(serialized["data"]?["relationships"]?["toys"])
        XCTAssertNotNil(serialized["data"]?["relationships"]?["pets"])
        XCTAssertNotNil(serialized["included"]?[0]?["relationships"]?["toys"])
    }
    
    func testWhitelist() throws {
        let user = User(firstName: "foo", lastName: "bar")
        let config = JSONAPIConfig(type: "users", whitelist: ["last-name"])
        let serializer = JSONAPISerializer(config: config)
        let serialized = try serializer.serialize(user)
        XCTAssertNil(serialized["data"]?["attributes"]?["first-name"])
        XCTAssertNotNil(serialized["data"]?["attributes"]?["last-name"])
    }
    
    func testBlacklist() throws {
        let user = User(firstName: "foo", lastName: "bar")
        let config = JSONAPIConfig(type: "users", blacklist: ["last-name"])
        let serializer = JSONAPISerializer(config: config)
        let serialized = try serializer.serialize(user)
        XCTAssertNil(serialized["data"]?["attributes"]?["last-name"])
    }
    
    func testSerilizeManyObjects() throws {
        let users = (0..<3).map { User(firstName: "foo\($0)", lastName: "bar\($0)") }
        let config = JSONAPIConfig(type: "users")
        let serializer = JSONAPISerializer(config: config)
        let serialized = try serializer.serialize(users)
        XCTAssertEqual(serialized["data"]?.array?.count, 3)
        
        for (index, data) in serialized["data"]!.array!.enumerated() {
            XCTAssertEqual(data["type"], "users")
            XCTAssertEqual(data["attributes"]?["first-name"]?.string, "foo\(index)")
            XCTAssertEqual(data["attributes"]?["last-name"]?.string, "bar\(index)")
        }
    }
    
    func testSerilizeSingleObject() throws {
        let user = User(firstName: "foo", lastName: "bar")
        let config = JSONAPIConfig(type: "users")
        let serializer = JSONAPISerializer(config: config)
        let serialized = try serializer.serialize(user)
        XCTAssertEqual(serialized["data"]?["type"], "users")
        XCTAssertEqual(serialized["data"]?["attributes"]?["first-name"], "foo")
        XCTAssertEqual(serialized["data"]?["attributes"]?["last-name"], "bar")
    }
}
