// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface val Endpoint
  new val from_uri(string: String)?
  fun to_uri(): String

primitive EndpointParser
  fun from_uri(string: String): Endpoint =>
    try EndpointTCP.from_uri(string) else
    try EndpointInProc.from_uri(string) else
        EndpointUnknown.from_uri(string)
    end end


class val EndpointUnknown is Endpoint
  let uri: String
  new val from_uri(string: String) => uri = string
  fun to_uri(): String => uri

class val EndpointTCP is Endpoint
  let schema: String = "tcp://"
  let host: String
  let port: String
  
  new val from_uri(string: String)? =>
    if not string.at(schema) then error end
    let parts = string.substring(schema.size().i64()).split(":")
    if 2 != parts.size() then error end
    host = parts(0)
    port = parts(1)
    if (0 == host.size()) or (0 == port.size()) then error end
  
  fun to_uri(): String =>
    schema + host + ":" + port

class val EndpointInProc is Endpoint
  let schema: String = "inproc://"
  let path: String
  
  new val from_uri(string: String)? =>
    if not string.at(schema) then error end
    path = string.substring(schema.size().i64())
  
  fun to_uri(): String =>
    schema + path
