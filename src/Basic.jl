export lsblock,
blockstat,
iscid

const qmprefix=startswith("Qm")
function iscid(s::AbstractString)
    qmprefix(s)&&length(s)==46
end

function blockstat(cid::String)
    iscid(cid)||throw(AssertionError("Not a CID"))
    readchomp(`$ipfscommand block stat $cid`)
    IPFSObject(cid)
end
blockstat(mfs::MFS)=blockstat(cid(mfs))

function download(ref::String;output::Union{Nothing,String}=nothing,compress::Bool=false,archive::Bool=compress,clevel::Int=5,
    progress::Bool=false)
    cmdhead=[ipfscommand,"get"]
    if archive
        push!(cmdhead,"--archive=true")
    end
    if compress
        push!(cmdhead,"--compress=true","--compression-level=$clevel")
    end
    if !progress
        push!(cmdhead,"--progress=false")
    end
    if !isnothing(output)
        local t=splitdir(output)[1]
        Base.isdir(t)||Base.mkpath(t)
        push!(cmdhead,"--output=$output")
    end
    push!(cmdhead,ref)
    run(Cmd(cmdhead))
end
download(s::AbstractIPFSObject;output=nothing,kwargs...)=download(cid(s);output=isnothing(output) ? name(s) : output,
    kwargs...)
function lsblock(ref::String)
    res=split(readchomp(`$ipfscommand ls $ref`),"\n")
    if res==[""]
        return nothing
    end
    map(res) do x 
        if x[48]=='-'
            split(x," - ")
        else
            t=split(x," ";limit=3)
            if length(t)!=3
                missing
            end
            t
        end
    end |> skipmissing
end
function lsblock(ref,::Type{Dict})
    res=map(lsblock(ref)) do x
        if length(x)==3
            x[1:2:3]
        else
            x
        end
    end
    Dict(res)
end
function lsblock(ref,::Type{AbstractIPFSObject})
    map(lsblock(ref)) do x
        x=map(String,x)
        if length(x)==3
            UnixFS(name=x[3],cid=x[1],size=parseint(x[2]))
        else
            UnixFS(name=x[2],cid=x[1])
        end
    end
end
ls(ref::AbstractIPFSObject)=lsblock(cid(ref))
function toIPFSPath(cid::AbstractString)
    "/ipfs/$cid"
end
toIPFSPath(s::AbstractIPFSObject)=cid(s)|>toIPFSPath
function base32(cid::String)
    readchomp(`$ipfscommand cid base32 $cid`)
end
base32(s::AbstractIPFSObject)=base32(cid(s))
function toBaseUrl(cid::AbstractString,webgate::String="localhost:8080")
    cid*".ipfs."*webgate
end
toBaseUrl(ref::AbstractIPFSObject,a...)=toBaseUrl(base32(ref),a...)
struct TimeoutError <: Exception
    readtimeout::Int
end
function get(s::AbstractIPFSObject,readtimeout::Integer=3,length::Integer=0;
    response_stream=nothing)
    cmdhead=[ipfscommand,"cat"]
    if !iszero(length)
        push!(cmdhead,"-l",string(length))
    end
    push!(cmdhead,cid(s))
    t=@async read(Cmd(Cmd(cmdhead),ignorestatus=true))
    if !istaskdone(t)
        sleep(readtimeout)
        istaskdone(t)||(throw(TimeoutError(readtimeout)))
    end
    if !isnothing(response_stream)
        write(response_stream,fetch(t))
        return response_stream
    end
    fetch(t)
end