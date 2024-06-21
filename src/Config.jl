export IPFSConfig,ipfsconfig,peerid,
localserverport,
boardcastip

struct IPFSConfig
    # configpath::AbstractString
end
const ipfsconfig=IPFSConfig()
Base.pathof(::IPFSConfig)=ENV["IPFS_PATH"]
function Base.getproperty(::IPFSConfig,name::Symbol)
    # if name==:configpath
    #     return getfield(values)
    readchomp(`$ipfscommand config $(String(name))`)
end

function Base.getproperty(::IPFSConfig,name::String)
    readchomp(`$ipfscommand config $name`)
end

peerid(x::IPFSConfig)=x."Identity.PeerID"
localserver(x::IPFSConfig)=x."Addresses.Gateway"

function localserverport()
    res=read(`$ipfscommand config Addresses.Gateway`)
    res=(parseint∘String)(res[end-4:end-1])
    global localgate="localhost:"*res
    res
end

function Base.replace!(x::IPFSConfig,old_new::Pair...)
    newconfig=replace(x.show, old_new..., count=1)
    open(joinpath(pathof(x),"config"),"w") do f
        write(f,newconfig)
    end
end

function boardcastip(x::IPFSConfig)
    replace!(x,"/ip4/127.0.0.1/tcp/8080" => "/ip4/0.0.0.0/tcp/8080")
end