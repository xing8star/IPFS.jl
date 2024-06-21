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
pwd::String="/"
function choosepath(path::String)
    if isabspath(path)
        path
    else
        joinpath(pwd,path)
    end
end

ipfscommand::String=determinecommand("ipfs")
ipfs_cmd_formatted::Vector{String}=[ipfscommand,"--enc","json"]
localgate::String="localhost:8080"
function checkenvvar()
    Base.haskey(ENV, "IPFS_PATH")||(ENV["IPFS_PATH"]=abspath(".repo"))
end
include("Timeout.jl")
function __init__()
    global ipfscommand
    checkenvvar()
    if isnothing(Sys.which(ipfscommand))
        @warn "IPFS command not found. Trying to use local IPFS daemon"
        ipfscommand=artifact"kubo"
        ipfscommand=joinpath(ipfscommand,"kubo","ipfs")
        ipfscommand=determinecommand(ipfscommand)
    end
    # ipfscommand=[ipfscommand,"--timeout=10s"]
end

const daemon_process=Ref{Base.Process}()
"""
    daemon(;waitseconds=nothing)
Set "waitseconds" will wait for seconds after call this.
"""
function daemon(;waitseconds=nothing)
    if !isdir(ENV["IPFS_PATH"])
        @info "Initial repo"  
        run(`$ipfscommand init`)
    end
    daemon_process[]=run(`$ipfscommand daemon`;wait=false)
    isnothing(waitseconds)||(sleep(waitseconds))
    daemon_process[]
end
function shutdown()
    run(`$ipfscommand shutdown`)    
end

include("IPFSObject.jl")
include("Block.jl")
include("MFS.jl")
include("Basic.jl")

"""
    toUrl(cid,webgate::String)
convert any contains `cid` to url.
`webgate` is the host.
"""
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
