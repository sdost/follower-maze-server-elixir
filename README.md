Follower Maze Server Test
=========================

##Dependencies
  - Erlang 19
  - Elixir 1.3.2

##Purpose
  This program is intended to solve the problem put forth in the document 'Back-end Developer Challenge: Follower Maze'. Given the input validation program, connect an event stream and 100 clients and properly route events to connected user clients.

##Usage
  ./follower_maze_server  

##Testing
  mix test

##Process
  The application creates a `Task` for each server, one to listen on 9090 for the event stream and one to listen on 9099 for client connections. The event server allows an event client to connect and then processes events as they are sent. An event handler is notified about each event, added to a `List` and sorted. Each incoming event also triggers trying to drain the ordered event list.

  The client server allows multiple clients to connect and stores their tcp sockets in a `Map`. Once the user is registered, events coming in are routed to the appropriate clients based on the rules set forth in the specification.

##Methodology
  This application starts four processes at launch: one `Task` for each server (User.Server & Event.Server), Event.Manager, and User.Manager. Event.Manager handles storage and draining of the event queue. User.Manager holds a `Map` of sockets for each user connection, as well as a `Map` of followers for each user based on Follow events. User.Manager also handles the side effects of each processed event.

##Performance
  The event stream processing should take O(n).  Processing each event should be either constant-time or O(n) depending on the event type.