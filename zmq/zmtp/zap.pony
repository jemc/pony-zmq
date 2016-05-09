// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

class val ZapRequest
  var version: String = "1.0"
  var id: String = ""
  var domain: String = ""
  var address: String = ""
  var identity: String = ""
  var mechanism: String = ""
  var credentials: Array[String] = credentials.create()
  
  var _responder: (ZapRespond | None) = None
  
  new iso create() => None
  fun ref push_credential(string: String) =>
    credentials.push(string)
  
  fun ref _set_responder(responder': ZapRespond) =>
    _responder = responder'
  
  fun respond(res: ZapResponse trn) =>
    res.version = version
    res.id      = id
    try (_responder as ZapRespond)(consume res) end
  
  new val from_message(m: Message)? =>
    let iter = m.values()
    version   = iter.next()
    id        = iter.next()
    domain    = iter.next()
    address   = iter.next()
    identity  = iter.next()
    mechanism = iter.next()
    for credential in iter do
      credentials.push(credential)
    end
  
  fun as_message(): Message => // TODO: test commutativity
    let out = recover trn Message end
    out.push(version)
    out.push(id)
    out.push(domain)
    out.push(address)
    out.push(identity)
    out.push(mechanism)
    for credential in credentials.values() do
      out.push(credential)
    end
    out

class val ZapResponse
  var version: String = "1.0"
  var id: String = ""
  var status_code: String = "200"
  var status_text: String = "OK"
  var user_id: String = ""
  var metadata: CommandMetadata = metadata.create()
  
  fun is_success(): Bool => status_code == "200"
  
  new iso create() => None
  
  new iso success(user_id': String = "") =>
    user_id  = user_id'
  
  new iso temp_error(status_text': String = "") =>
    status_code = "300"
    status_text = status_text'
  
  new iso auth_error(status_text': String = "") =>
    status_code = "400"
    status_text = status_text'
  
  new iso server_error(status_text': String = "") =>
    status_code = "500"
    status_text = status_text'
  
  new val from_message(m: Message)? =>
    let iter = m.values()
    version     = iter.next()
    id          = iter.next()
    status_code = iter.next()
    status_text = iter.next()
    user_id     = iter.next()
    CommandUtil.read_string_as_metadata(metadata, iter.next())
    if iter.has_next() then error end
  
  fun as_message(): Message => // TODO: test commutativity
    let out = recover trn Message end
    out.push(version)
    out.push(id)
    out.push(status_code)
    out.push(status_text)
    out.push(user_id)
    out.push(CommandUtil.write_string_as_metadata(metadata))
    out

interface tag ZapRequestNotifiable
  be handle_zap_request(req: ZapRequest, respond: ZapRespond)

interface val ZapRespond
  fun val apply(zap: ZapResponse)
