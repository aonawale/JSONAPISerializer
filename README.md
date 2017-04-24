# JSONAPISerializer for Vapor

Serialize Vapor models into JSONAPI compliant structures.

## Basic usage

```swift
import Vapor
import JSONAPISerializer

let config = JSONAPIConfig(type: "users")
let serializer = JSONAPISerializer(config: config)

let users: [User]...
try serializer.serialize(users)
```

### Produces
```
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
  }]
}
```

## Relationships

```swift
let toysConfig = JSONAPIConfig(type: "toys")
let petsConfig = JSONAPIConfig(type: "pets", relationships: ["toys": toysConfig])
let userConfig = JSONAPIConfig(type: "users", relationships: ["pets": petsConfig])
let serializer = JSONAPISerializer(config: userConfig)

let users: [User]...
try serializer.serialize(users)
```

### Produces
```
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
  "included": [
    {
      "attributes": {
        "name": "dog",
        "user_id": 1
      },
      "id": 1,
      "type": "pets"
    },
    {
      "attributes": {
        "name": "bone",
        "pet_id": 1
      },
      "id": 1,
      "type": "toys"
    }
  ]
}
```

## Roadmap

- Dasherized, underscored and camel cased keys support.


## License

JSONAPISerializer is available under the MIT license. See the LICENSE file for more information.