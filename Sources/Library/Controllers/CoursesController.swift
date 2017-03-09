import Vapor
import HTTP

public final class CoursesController: ResourceRepresentable {
    var droplet: Droplet
    public init(droplet: Droplet) {
        self.droplet = droplet
    }

    // replace, clear, about* -- ?
    public func makeResource() -> Resource<Course> {
        return Resource(
            index: index,
            store: store,
            show: show,
            modify: update,
            destroy: destroy
        )
    }
    
    public func registerRoutes() {
        droplet.group("courses", ":id") { courses in
            courses.get("users", handler: users)
        }
    }


    /// GET /: Show all course entries.
    public func index(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: Course.all().makeNode())
    }

    /// POST: Add a new course entry.
    public func store(request: Request) throws -> ResponseRepresentable {
        var course = try request.course()
        try course.save()
        try RealtimeController.send(try JSON(node: [
            "endpoint": "courses",
            "method": "store",
            "item": course
        ]))
        return course
    }

    /// GET: Show the course entry.
    public func show(request: Request, course: Course) throws -> ResponseRepresentable {
        return course
    }

    /// PUT: Update the course entry completely.
    public func update(request: Request, course: Course) throws -> ResponseRepresentable {
        let newCourse = try request.course()
        var course = course
        course.title = newCourse.title
        course.name = newCourse.name
        course.enrollment = newCourse.enrollment
        try course.save()
        try RealtimeController.send(try JSON(node: [
            "endpoint": "courses",
            "method": "update",
            "item": course
        ]))
        return course
    }

    /// DELETE: Delete the course entry and return the course that was deleted.
    public func destroy(request: Request, course: Course) throws -> ResponseRepresentable {
        let ret_course = course
        try course.delete()
        try RealtimeController.send(try JSON(node: [
            "endpoint": "courses",
            "method": "destroy",
            "item": ret_course
        ]))
        return ret_course
    }
    
    /// GET: Returns the users enrolled in a course
    public func users(request: Request) throws -> ResponseRepresentable {
        guard let courseId = request.parameters["id"]?.int else {
            // Bad course id in request
            throw Abort.badRequest
        }
        guard let course = try Course.find(courseId) else {
            // Course doesn't exist
            throw Abort.notFound
        }
        guard let user = try User.authenticateWithToken(fromRequest: request) else {
            // Auth token not provided or token not valid
            return try JSON(node: ["error" : "Not authorized"]).makeResponse()
        }
        if try course.users().filter("id", user.id!).all().isEmpty {
            // User making request is not enrolled in the specified course
            return try JSON(node: ["error" : "Not authorized"]).makeResponse()
        }
        
        return try JSON(node: course.users().all().makeNode(context: UserSensitiveContext()))
    }

}
