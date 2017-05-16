use zmq = "../../zmq"
use net = "net"

actor Main is zmq.SocketNotifiableActor
  """
  This program will create a ZeroMQ REQ socket, and expect to connect to another
  ZeroMQ REP socket running on localhost on port 9999.
  
  It will send a single message composed of the command-line arguments to the
  program. If no arguments were provided, an empty message will be sent.
  
  When a response to the request is received from the other socket, the message
  will be printed and this program will be terminated.
  
  Run the echo-rep example, then run this example to send it a message.
  """
  let _env: Env
  
  new create(env: Env) =>
    _env = env
    
    match _env.root | let root: AmbientAuth =>
      let socket = zmq.Socket(zmq.REQ, zmq.SocketNotifyActor(this))
      
      socket(zmq.ConnectTCP(net.NetAuth(root), "localhost", "9999"))
      
      let message = recover val
        zmq.Message .> concat(_env.args.slice(1).values())
      end
      
      socket.send(message)
      
      _env.out.print("REQ sent: " + message.string())
    else
      _env.out.print("REQ error: couldn't create NetAuth")
    end
  
  be received(socket: zmq.Socket, peer: zmq.SocketPeer, message: zmq.Message) =>
    """
    When we receive a response to our request, we want to print it and then
    dispose of the socket, which will terminate the program because no other
    actor is left active (Pony programs terminate after reaching quiesence).
    """
    _env.out.print("REQ received: " + message.string())
    
    socket.dispose()
