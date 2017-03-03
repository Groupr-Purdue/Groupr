import Vapor
import Fluent
import HTTP

public final class Group: Model {
    public var id: Node?
    public var exists: Bool = false

    /// The group's name (i.e. 'Team 24').
    public var name: String

    /// The group's connected course (i.e. CS 408).
    public var courseid: Int

    /// The designated initializer.
    public init(name: String, courseid: Int) {
        self.id = nil
        self.name = name
        self.courseid = courseid
    }

    /// Internal: Fluent::Model::init(Node, Context).
    public init(node: Node, in context: Context) throws {
        self.id = try node.extract("id")
        self.name = try node.extract("name")
        self.courseid = try node.extract("courseid")
    }

    /// Internal: Fluent::Model::makeNode(Context).
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "name": name,
            "courseid": courseid
        ])
    }

    /// Establish a many-to-many relationship with User.
    public func course() throws -> Parent<User> {
        return try parent(self.id)
    }
}

extension Group: Preparation {

    /// Create the Course schema when required in the database.
    public static func prepare(_ database: Database) throws {
        try database.create("groups", closure: { (groups) in
            groups.id()
            groups.parent(Course.self)
            groups.string("name", length: nil, optional: false, unique: true, default: nil)
        })
    }

    /// Delete/revert the Course schema when required in the database.
    public static func revert(_ database: Database) throws {
        try database.delete("groups")
    }
}

public extension Request {
    public func group() throws -> Group {
        guard let json = self.json else {
            throw Abort.badRequest
        }
        return try Group(node: json)
    }
}
