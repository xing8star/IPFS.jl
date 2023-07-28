# @enum MFStype file directory
export MFS,UnixFS,
CIDInfo1,
CIDInfo2,
CIDInfo3,
AbstractIPFSObjectInfo,
@ipfs_str,
cid,name,
isfileordir
using FilePathsBase
abstract type MFS<:AbstractIPFSObject end
abstract type FSType end
struct File<:FSType end
struct Directory<:FSType end
abstract type AbstractIPFSObjectInfo end
struct EmptyInfo <: AbstractIPFSObjectInfo end
struct CIDInfo1 <: AbstractIPFSObjectInfo
    name::String
end
struct CIDInfo2 <: AbstractIPFSObjectInfo
    name::String
    size::Int
end
struct CIDInfo3 <: AbstractIPFSObjectInfo
    name::String
    size::Int
    CumulativeSize::Int
    ChildBlocks::Int
end
struct UnixFS{FSType,T<:AbstractIPFSObjectInfo} <:MFS
    cid::IPFSObject
    info::T
end
name(info::AbstractIPFSObjectInfo)=info.name
name(::EmptyInfo)=nothing
name(s::UnixFS{T,EmptyInfo}) where T=cid(s)

function MFStype(s::AbstractString)
    if s=="directory"||endswith(s,"/")
        Directory
    else
        File
    end
end

UnixFS{T}(cid::AbstractString,name::AbstractString,size::Int) where T<:FSType=UnixFS{T,CIDInfo2}(IPFSObject(cid),CIDInfo2(name,size))

UnixFS{T}(cid::AbstractString,name::AbstractString) where T<:FSType=UnixFS{T,CIDInfo1}(IPFSObject(cid),CIDInfo1(name))
UnixFS{T}(cid::AbstractString,name::AbstractString,size::Int,
CumulativeSize::Int,ChildBlocks::Int) where T<:FSType=UnixFS{T,CIDInfo3}(IPFSObject(cid),CIDInfo3(name,size,CumulativeSize,ChildBlocks))

UnixFS{T}(cid::AbstractString) where T<:FSType=UnixFS{T}(cid,cid)
UnixFS{T}(cid::AbstractString,emptyname::Bool) where T<:FSType=if emptyname UnixFS{T}(cid,EmptyInfo()) else UnixFS{T}(cid) end

function UnixFS(;cid::AbstractString,name::AbstractString=cid,size=nothing,CumulativeSize=nothing,ChildBlocks=nothing,
    fstype::AbstractString=name)
    fstype=MFStype(fstype)
    if isnothing(ChildBlocks)&&isnothing(size)
        UnixFS{fstype}(cid,name)
    elseif isnothing(ChildBlocks)
        UnixFS{fstype}(cid,name,size)
    else
        UnixFS{fstype}(cid,name,size,CumulativeSize,ChildBlocks)
    end
end
@delegate_onefield(AbstractIPFSObject,cid,[cid])
@delegate_onefield(AbstractIPFSObject,info,[name])
CIDInfo1(s::Union{CIDInfo2,CIDInfo3})=CIDInfo1(name(s))
CIDInfo2(s::CIDInfo3)=CIDInfo2(name(s),s.size)
CIDInfo2(s::CIDInfo1)=CIDInfo2(name(s),0)
CIDInfo3(s::CIDInfo1)=CIDInfo3(name(s),0,0,0)
CIDInfo3(s::CIDInfo2)=CIDInfo3(name(s),s.size,0,0)
CIDInfo3(name::AbstractString,s::CIDInfo3)=CIDInfo3(name,s.size,s.CumulativeSize,s.ChildBlocks)

UnixFS{CIDInfo1}(s::UnixFS{T,<:Union{CIDInfo2,CIDInfo3}}) where T<:FSType=UnixFS{T,CIDInfo1}(s.cid,CIDInfo1(s.info))
UnixFS{CIDInfo2}(s::UnixFS{T,<:Union{CIDInfo1,CIDInfo3}}) where T<:FSType=UnixFS{T,CIDInfo2}(s.cid,CIDInfo2(s.info))
# UnixFS{T,CIDInfo3}(s::UnixFS{T,Union{CIDInfo1,CIDInfo3}}) where T<:FSType=UnixFS{T,CIDInfo3}(s.cid,CIDInfo3(s.info))

function UnixFS{CIDInfo3}(s::UnixFS{T,Union{CIDInfo1,CIDInfo2}},requery::Bool=true) where T<:FSType
    if requery
        UnixFS{T,CIDInfo3}(s.cid,CIDInfo3(name(s),stat(s).info))
    else
        UnixFS{CIDInfo3}(s.cid,CIDInfo3(s.info))
    end
end
function UnixFS{CIDInfo2}(s::UnixFS{T,CIDInfo1},requery::Bool=true) where T<:FSType
    if requery
        UnixFS{T,CIDInfo2}(s.cid,CIDInfo2(stat(s).info))
    else
        UnixFS{CIDInfo2}(s)
    end
end
Base.isdir(::UnixFS)::Bool=false
Base.isdir(::UnixFS{Directory})::Bool=true
Base.isfile(::UnixFS{File})::Bool=true
Base.isfile(::UnixFS)::Bool=false

function isexitedfileordir(path::AbstractString)::Bool
    local list
    # a,b=splitdir(path)
    try
        ls(path)
    catch
        false
    else
        true
    end
    # if b in 
    #     true
    # else
    #     false
    # end
end
isfileordir(path::AbstractString)::Bool=isexitedfileordir(choosepath(path))

function cd(path::String)
	global pwd
    pwd=if path==".."
        # splitdir(pwd[begin:end-1])[begin]
        Path(pwd)|>parent|>string
    elseif path=="."
        pwd
    elseif path=="/"
        "/"
    else
        choosepath(path)
    end
    if pwd[end]!='/'
        pwd*='/'
    end
    pwd
end

function cp(source::String,dest::String;parents::Bool=false)
    if parents
        run(`$ipfscommand files cp -p $(choosepath(source)) $(choosepath(dest))`)
    else
        run(`$ipfscommand files cp $(choosepath(source)) $(choosepath(dest))`)
    end
end
function cp(source::AbstractIPFSObject,dest::String;parents::Bool=false)
    cp(toIPFSPath(source),dest;parents)
end
function cp(source::MFS,dest::String;parents::Bool=false)
    cp(toIPFSPath(source),joinpath(choosepath(dest),name(source));parents)
end
function rm(path::String;recursive::Bool=false)
    if recursive
        run(`$ipfscommand files rm -r $(choosepath(path))`)
    else
        run(`$ipfscommand files rm $(choosepath(path))`)
    end
end

function ls(;join::Bool=false)
    ls(pwd;join)
end
function ls(path::String;join::Bool=false)
    res=split(readchomp(`$ipfscommand files ls $(choosepath(path))`),"\n")
    if res==[""]
        return res
    end
    if join
        joinpath(pwd,path*"/").*res
    else
        res
    end
end

function _UnixFS(items::SubString)
    items=String(items)
    i=split(items,r"\t")
    UnixFS{MFStype(i[1])}(i[2],i[1],parseint(i[3]))
end
function UnixFS(res::SubString)
    [_UnixFS(i) for i in split(res, "\n")]
end

function readdir(path::String)
    res=readchomp(`$ipfscommand files ls -l $(choosepath(path))`)
    UnixFS(res)
end
function UnixFS(name::AbstractString,
    cid::AbstractString,
    size::AbstractString,
    CumulativeSize::AbstractString,
    ChildBlocks::AbstractString,
    fstype::AbstractString)
    UnixFS(;name,cid,size=parseint(size),
    CumulativeSize=parseint(CumulativeSize),ChildBlocks=parseint(ChildBlocks),fstype)
end
function UnixFS(name::String,res::AbstractString)
    res=split(res, "\n")
    UnixFS(name,res[1],map(x->split(x,": ")[2],res[2:end])...)
end
# ,ignorestatus=true
function stat(path::String)
    res=readchomp(Cmd(`$ipfscommand files stat $(choosepath(path))`))
    if isempty(res)
        nothing
    else
        UnixFS(basename(path),res)
    end
end
function stat(s::AbstractIPFSObject)
    c=cid(s)
    res=readchomp(Cmd(`$ipfscommand files stat $(toIPFSPath(c))`))
    if isempty(res)
        nothing
    else
        UnixFS(c,res)
    end
end

function mv(source::String,dest::String)
    run(`$ipfscommand files mv $(choosepath(source)) $(choosepath(dest))`)
end
function mkdir(dirname::String)
    run(`$ipfscommand files mkdir $(choosepath(dirname))`)
end
function mkpath(path::String)
    run(`$ipfscommand files mkdir -p $(choosepath(path))`)
end

function _add(file::String;recursive::Bool=false,progress=true,quiet=false,
    pin=false)
    cmdhead=[ipfscommand,"add"]
    push!(cmdhead,file)
	if recursive
        push!(cmdhead,"--recursive")
    end
    if !progress
        push!(cmdhead,"--progress=false")
    end
    if quiet
        push!(cmdhead,"--quiet")
    end
    if !pin
        push!(cmdhead,"--pin=false")
    end
    cmdhead
end

function add(file::String,path::String;recursive::Bool=false,progress::Bool=false,quiet::Bool=true,
    pin::Bool=false,addReference::Bool=true)
    cmdhead=_add(file;recursive,progress,quiet,pin)
    if addReference
        push!(cmdhead,"--to-files",choosepath(path))
    end
    res=read(Cmd(cmdhead))
    # String(res[7:52])
    String(res[begin:end-1])
end
function add(file::String;kwargs...)
    add(file,pwd;kwargs...)
end
macro ipfs_str(expr)
    elem=split(expr).|>String
    :($(Symbol(elem[1]))($(elem[2:end]...)))
end