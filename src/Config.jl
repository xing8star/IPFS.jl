export IPFSConfig,ipfsconfig,peerid,localserverport

struct IPFSConfig end
const ipfsconfig=IPFSConfig()
function Base.getproperty(::IPFSConfig,name::Symbol)
    readchomp(`$ipfscommand config $(String(name))`)
end

function Base.getproperty(::IPFSConfig,name::String)
    readchomp(`$ipfscommand config $name`)
end

peerid()=ipfsconfig."Identity.PeerID"
localserver()=ipfsconfig."Addresses.Gateway"

function localserverport()
    res=read(`$ipfscommand config Addresses.Gateway`)
    (parseint∘String)(res[end-4:end-1])
end