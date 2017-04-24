# JSONAPISerializer for Vapor

Serialize Vapor models into JSONAPI compliant structures.

## Usage

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