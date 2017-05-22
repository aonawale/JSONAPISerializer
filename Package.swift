import PackageDescription

let package = Package(
    name: "JSONAPISerializer",
    dependencies: [
      // Core protocols, extensions, and functionality
      .Package(url: "https://github.com/vapor/core.git", majorVersion: 2),

      // Data structures for converting between multiple representations
       .Package(url: "https://github.com/vapor/json.git", majorVersion: 2),
       .Package(url: "https://github.com/vapor/node.git", majorVersion: 2)
    ]
)

