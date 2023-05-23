module IPFS
using Artifacts

export ipfscommand,
    toUrl,toLocalUrl,@ipfscli_str

ipfscommand=if Sys.islinux()
    `ipfs`
elseif Sys.iswindows()
    `ipfs.exe`
end
const localgate=Ref("")

macro ipfscli_str(expr)
    c=`$ipfscommand $expr`
    :(run($c))
end

pwd="/"

function checkenvvar()
    Base.get(ENV, "IPFS_PATH") do
        ENV["IPFS_PATH"]=abspath("./.repo")
    end
end
parseint(s)=parse(Int,s)
function __init__()
    checkenvvar()
    try
        run(ipfscommand;wait=false)
    catch ex
        if ex isa Base.IOError
            ipfscommand=artifact"kubo"
            ipfscommand=joinpath(ipfscommand,"kubo")
            ipfscommand=if Sys.islinux()
                joinpath(ipfscommand,"ipfs")
            elseif Sys.iswindows()
                joinpath(ipfscommand,"ipfs.exe")
            end
        end
    end
    localgate[]="localhost:"*string(localserverport())
end
function daemon()
    res=run(`$ipfscommand daemon`;wait=false)
    if res.exitcode==1
        @info "Initial repo"  
        run(`$ipfscommand init`)
        res=run(`$ipfscommand daemon`;wait=false)
    end
    res
end
include("MFS.jl")

function shutdown()
    run(`ipfs shutdown`)
end
function choosepath(path::String)
    if isabspath(path)
        path
    else
        joinpath(pwd,path)
    end
end

include("cid.jl")

function toUrl(cid::String,webgate::String)
    webgate*"/ipfs/"*cid
end

function toUrl(cid::MFS,webgate::String)
    toUrl(getcid(cid),webgate)
end

function toLocalUrl(cid::Union{String,MFS})
    toUrl(cid,localgate[])
end

include("Config.jl")

end # module IPFS
