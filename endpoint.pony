
use "regex"

type Endpoint is
  ( EndpointUnknown
  | EndpointTCP)

primitive EndpointUnknown

class EndpointTCP val
  let schema: String = "tcp://"
  var host: String
  var port: String
  
  new val from_uri(string: String) ? =>
    if not string.at(schema) then error end
    let parts = string.substring(schema.size().i64()).split(":")
    if 2 != parts.size() then error end
    host = parts(0)
    port = parts(1)
    if (0 == host.size()) or (0 == port.size()) then error end
  
  fun to_uri(): String =>
    schema + host + ":" + port
