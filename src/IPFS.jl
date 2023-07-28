module IPFS
using LazyArtifacts

export ipfscommand,
    toUrl,toLocalUrl,@ipfscli_str,
    IPFSObject

macro ipfscli_str(expr)
    c=Cmd(String[ipfscommand,split(expr)...])
    :(run($c))
end
include("OtherTools.jl")
using .MyTools
using .MyTools:parseint
pwd="/"
function choosepath(path::String)
    if isabspath(path)
        path
    else
        joinpath(pwd,path)
    end
end

ipfscommand=determinecommand("ipfs")
localgate="localhost:8080"
function checkenvvar()
    Base.haskey(ENV, "IPFS_PATH")||(ENV["IPFS_PATH"]=abspath(".repo"))
end

function __init__()
    checkenvvar()
    try
        run(ipfscommand;wait=false)
    catch ex
        if ex isa Base.IOError
            ipfscommand=artifact"kubo"
            ipfscommand=joinpath(ipfscommand,"kubo")
            ipfscommand=determinecommand(ipfscommand)
        end
    end
end
function daemon(;waitseconds=nothing)
    if !isdir(ENV["IPFS_PATH"])
        @info "Initial repo"  
        run(`$ipfscommand init`)
    end
    global daemon_process=run(`$ipfscommand daemon`;wait=false)
    isnothing(waitseconds)||(sleep(waitseconds))
    daemon_process
end
function shutdown()
    run(`$ipfscommand shutdown`)    
end

include("IPFSObject.jl")
include("MFS.jl")
include("Basic.jl")

function toUrl(cid::String,webgate::String)
    webgate*"/ipfs/"*cid
end

function toUrl(mfs::MFS,webgate::String)
    toUrl(cid(mfs),webgate)
end
function toUrl(webgate::String)
    x->toUrl(cid(x),webgate)
end
function toLocalUrl(cid::Union{String,MFS})
    toUrl(cid,localgate)
end

include("Config.jl")

end # module IPFS
