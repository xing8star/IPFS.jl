export IPFSConfig,ipfsconfig,peerid,
localserverport,
changeconfig,
changelistenip

struct IPFSConfig
    # configpath::AbstractString
end
const ipfsconfig=IPFSConfig()
function Base.getproperty(::IPFSConfig,name::Symbol)
    # if name==:configpath
    #     return getfield(values)
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

function changeconfig(old_new::Pair...)
    newconfig=replace(ipfsconfig.show, old_new..., count=1)
    open(joinpath(ENV["IPFS_PATH"],"config"),"w") do f
        write(f,newconfig)
    end

end

function changelistenip()
    changeconfig("/ip4/127.0.0.1/tcp/8080" => "/ip4/0.0.0.0/tcp/8080")
end