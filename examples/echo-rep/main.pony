use zmq = "../../zmq"
use net = "net"

actor Main is zmq.SocketNotifiableActor
  """
  This program will create a ZeroMQ REP socket bound to localhost on port 9999.
  It will act as a simple echo server, accepting messages from connecting REQs,
  replying with the exact message that it received, and printing it to STDOUT.
  
  Run this example, then run the echo-req example to send it a message.
  """
  let _env: Env
  
  new create(env: Env) =>
    _env = env
    
    match _env.root | let root: AmbientAuth =>
      let socket = zmq.Socket(zmq.REP, zmq.SocketNotifyActor(this))
      
      socket(zmq.BindTCP(net.NetAuth(root), "localhost", "9999"))
    else
      _env.out.print("REP error: couldn't create NetAuth")
    end
  
  be received(socket: zmq.Socket, peer: zmq.SocketPeer, message: zmq.Message) =>
    """
    When we receive a request, we want to send the same message back to the peer
    unchanged (echo it) then print it to STDOUT for posterity.
    """
    peer.send(message)
    
    _env.out.print("REP received/sent: " + message.string())
