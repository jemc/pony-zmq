
class ZapRequest val
  var domain: String = ""
  var address: String = ""
  var identity: String = ""
  var mechanism: String = ""
  var credentials: Array[String] = credentials.create()
  new iso create() => None
  fun ref push_credential(string: String) =>
    credentials.push(string)
