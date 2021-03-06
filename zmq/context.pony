// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"

actor Context
  let _ready_binds: Map[String, _SocketBindInProc]       = _ready_binds.create()
  let _ready_peers: Map[String, List[_SocketPeerInProc]] = _ready_peers.create()
  
  be _inproc_bind(string: String, bind: _SocketBindInProc) =>
    // If there is not already a bind for this string
    if not _ready_binds.contains(string) then
      // Set this bind as the bind for this string
      _ready_binds(string) = bind
      
      // Connect peers that are already waiting for a bind
      try let peers = _ready_peers(string)?
        for peer in peers.values() do
          bind.accept_connection(peer)
        end
      end
    end
  
  be _inproc_connect(string: String, peer: _SocketPeerInProc) =>
    // Add this peer to peer list for this string
    let peer_list = try _ready_peers(string)? else
                      let list = List[_SocketPeerInProc]
                      _ready_peers(string) = list
                      list
                    end
    peer_list.push(peer)
    
    // Connect to a bind if there is one available
    try _ready_binds(string)?.accept_connection(peer) end
