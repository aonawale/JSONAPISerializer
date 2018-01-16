# JSONAPISerializer for Server Side Swift

Serialize Swift objects into JSONAPI compliant structures.

## Basic usage

```swift
import JSON
import JSONAPISerializer

struct User: JSONRepresentable {
    var id: Node?
    let firstName: String
    let lastName: String

    func makeJSON() throws -> JSON {
        var json = JSON([:])
        try json.set("id", id)
        try json.set("first-name", firstName)
        try json.set("last-name", lastName)
        return json
    }
}

let config = JSONAPIConfig(type: "users")
let serializer = JSONAPISerializer(config: config)

let users: [User]...
try serializer.serialize(users)
```

### Produces
```js
{
  "data": [{
    "type": "users",
    "id": "1",
    "attributes": {
      "first-name": "foo",
      "last-name": "bar"
    }
  }, {
    "type": "users",
    "id": "2",
    "attributes": {
      "first-name": "John",
      "last-name": "Doe"
    }
  }],
  "jsonapi": {
    "version": "1.0"
  },
  "links": {
    "self": "/users"
  },
  "meta": {}
}
```

## Relationships

```swift
let petsConfig = JSONAPIConfig(type: "pets")
let profileConfig = JSONAPIConfig(type: "profiles", relationships: ["pets": petsConfig])
let userConfig = JSONAPIConfig(type: "users", relationships: ["profile": profileConfig])
let serializer = JSONAPISerializer(config: userConfig)

let users: [User]...
try serializer.serialize(users)
```

### Produces
```js
{
  "data": [
    {
      "id": 2,
      "type": "users",
      "attributes": {
        "first-name": "foo",
        "last-name": "bar"
      },
      "relationships": {
        "profile": {
          "data": {
            "id": 2,
            "type": "profiles"
          }
        }
      }
    }
  ],
  "included": [
    {
      "attributes": {
        "age": 18,
        "user-id": 2,
      },
      "id": 2,
      "relationships": {
        "pets": {
          "data": [
            {
              "id": 5,
              "type": "pets"
            },
            {
              "id": 8,
              "type": "pets"
            }
          ]
        }
      },
      "type": "profiles"
    },
    {
      "attributes": {
        "pet-name": "dog",
        "profile-id": 2
      },
      "id": 5,
      "relationships": {},
      "type": "pets"
    },
    {
      "attributes": {
        "pet-name": "cat",
        "profile-id": 2
      },
      "id": 8,
      "relationships": {},
      "type": "pets"
    }
  ],
  "jsonapi": {
    "version": "1.0"
  },
  "links": {
    "self": "/users"
  },
  "meta": {}
}
```

## Roadmap

- Dasherized, underscored and camel cased keys support.


## License

JSONAPISerializer is available under the MIT license. See the LICENSE file for more information.
