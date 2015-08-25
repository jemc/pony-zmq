
use "collections"

class ZapRequest val
  var domain: String = ""
  var address: String = ""
  var identity: String = ""
  var mechanism: String = ""
  var credentials: Array[String] = credentials.create()
  new iso create() => None
  fun ref push_credential(string: String) =>
    credentials.push(string)

class ZapResponse val
  var status_code: String = "200"
  var status_text: String = "OK"
  var user_id: String = ""
  var metadata: Map[String, String] = metadata.create()
  new iso create() => None
  fun is_success(): Bool => status_code == "200"

interface ZapResponseNotifiable tag
  be notify_zap_response(zap: ZapResponse)
