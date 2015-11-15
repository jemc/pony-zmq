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
  new iso create() => None
  fun ref push_credential(string: String) =>
    credentials.push(string)
  
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
  new iso create() => None
  fun is_success(): Bool => status_code == "200"
  
  new val server_error(text: String) =>
    status_code = "503"
    status_text = text
  
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

interface tag ZapResponseNotifiable
  be notify_zap_response(zap: ZapResponse)
