export lsblock,
blockstat,
iscid
using SafeThrow
const qmprefix=startswith("Qm")

"""
    iscid(cid::AbstractString) -> Bool

Return true if the given value is a cid.

# Examples
```julia-repl
julia> iscid("QmbA2UcUN6R65jTCZcgfBgN87KvnSMvoQwrJWz6P3huv4o")
true
```
"""
function iscid(s::AbstractString)
    qmprefix(s)&&length(s)==46
end

"""
    blockstat(cid)

Print information of a raw IPFS block.
"""
function blockstat(cid::String)
    iscid(cid)||throw(AssertionError("Not a CID"))
    readchomp(`$ipfscommand block stat $cid`)
    IPFSObject(cid)
end
blockstat(mfs::MFS)=blockstat(cid(mfs))

"""
    download(cid;output::Union{Nothing,String}=nothing,compress::Bool=false,archive::Bool=compress,clevel::Int=5,progress::Bool=false)

Stores to disk the data contained an IPFS or IPNS object(s) at the given path.

By default, the output will be stored at './<ipfs-path>', but an alternate
path can be specified with `output=<path>`.

To output a TAR archive instead of unpacked files, use `archive` or '-a'.

To compress the output with GZIP compression, use `compress` . You
may also specify the level of compression by specifying `clevel=<1-9>`.

"""
function download(ref::String,::Nothing=nothing;compress::Bool=false,archive::Bool=compress,clevel::Int=5,
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
    push!(cmdhead,ref)
    run(Cmd(cmdhead))
end

function download(ref::String,output::String;compress::Bool=false,archive::Bool=compress,clevel::Int=5,
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
    local t=splitdir(output)[1]
    Base.isdir(t)||Base.mkpath(t)
    push!(cmdhead,"--output=$output")

    push!(cmdhead,ref)
    run(Cmd(cmdhead))
end
download(s::AbstractIPFSObject;output=nothing,kwargs...)=download(cid(s),output=isnothing(output) ? name(s) : output;
    kwargs...)

"""
    lsblock(ref::String)
    lsblock(ref::String,::T<:Union{Dict,AbstractIPFSObject})

Return the names in the IPFS directory dir,or convert to the given type.
"""
function lsblock(ref::String)
    res=split(readchomp(`$ipfscommand ls $ref`),"\n")
    if isempty(res)
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
Base.convert(::Type{TimeoutError},s::Timeout)=TimeoutError(s.num)

struct IntergerOption
    optionname::String
    value::Integer
end
function Base.string(s::IntergerOption)
    if s.value<=0 return "" end
    "--"*s.optionname*"="*string(s.value)
end
Base.push!(cmds::Vector{String},i::IntergerOption)=if i.value>0 push!(cmds,string(i)) end
# macro IntergerOption(var)
#     :(IntergerOption($(string(var)),$var))
# end

Base.convert(::Type{String},s::IntergerOption)=string(s)



@add_safefunction function get(s::AbstractIPFSObject,readtimeout::Timeout=TIMEOUT,length::Integer=0;
    response_stream=nothing,offset::Int=0,ignorestatus=true)
    cmdhead=String[ipfscommand,readtimeout,"cat"]
    # filter(!=(""),
    push!(cmdhead,IntergerOption("length",length))
    push!(cmdhead,IntergerOption("offset",offset))
    push!(cmdhead,cid(s))
    t=read(Cmd(Cmd(cmdhead);ignorestatus))
    if !ignorestatus
        throw(TimeoutError(readtimeout))
    end
    if !isnothing(response_stream)
        write(response_stream,t)
        return response_stream
    end
    t
end

"""
    get(s::AbstractIPFSObject,readtimeout::Timeout=TIMEOUT,length::Integer=0;response_stream=nothing,ignorestatus=true)

    return `response_stream` of the data contained by an IPFS or IPNS object(s) at the given path.
"""
get

function hash(path::AbstractString)
    cmdhead=[ipfscommand,"add","-Q","-n",choosepath(path)]
    res=read(Cmd(cmdhead))
    String(res[begin:end-1])
end

function islocalblock(s::AbstractIPFSBlock)
    cmdhead=String[ipfscommand,Timeout(10,"ms"),"block","stat",cid(s)]
    if run(Cmd(cmdhead);wait=false).exitcode!=0
        false
    else
        true
    end
end