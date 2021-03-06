import Vapor
import HTTP

public final class EventsController: ResourceRepresentable {
    var droplet: Droplet
    public init(droplet: Droplet) {
        self.droplet = droplet
    }

    public func makeResource() -> Resource<Event> {
        return Resource(
            index: index,
            store: store,
            show: show
        )
    }

    /// GET /: Show all event entries.
    public func index(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: Event.all().makeNode())
    }

    /// POST: Add a new event entry.
    public func store(request: Request) throws -> ResponseRepresentable {
        var event = try request.event()
        try event.save()
        try RealtimeController.send(try JSON(node: [
            "endpoint": "events",
            "method": "store",
            "item": event
        ]))
        return event
    }

    /// GET: Show the event entry.
    public func show(request: Request, event: Event) throws -> ResponseRepresentable {
        return event
    }
}
