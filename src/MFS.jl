# @enum MFStype file directory
export MFS,MFSblock,MFSfile,@ipfs_str

abstract type MFS end
struct MFSfile <:MFS
    name::String
    cid::String
    Size::Int
end
struct MFSblock <:MFS
    file::MFSfile
    CumulativeSize::Int
    ChildBlocks::Int
    MFStype::String
end
getcid(mfs::MFSfile)::String=mfs.cid
getcid(mfs::MFSblock)::String=getcid(mfs.file)
getname(mfs::MFSfile)::String=mfs.name
getname(mfs::MFSblock)::String=getname(mfs.file)

function cd(path::String)
	global pwd
    if path==".."
        pwd=splitdir(pwd[begin:end-1])[begin]
    else
        pwd=choosepath(path)
    end
    if pwd[end]!="/"
        pwd*="/"
    end
end

function cp(source::String,dest::String;parents::Bool=false)
    if parents
        run(`$ipfscommand files cp -p $(choosepath(source)) $(choosepath(dest))`)
    else
        run(`$ipfscommand files cp $(choosepath(source)) $(choosepath(dest))`)
    end
end
function cp(source::MFS,dest::String;parents::Bool=false)
    cp("/ipfs/"*getcid(source),dest;parents)
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
    if join
        pwd.*res
    else
        res
    end
end

function _MFSfile(items::SubString)
    items=String(items)
    i=split(items,"\t")
    MFSfile(i[1],i[2],parseint(i[3]))
end
function MFSfile(res::SubString)
    [_MFSfile(i) for i in split(res, "\n")]
end

function readdir(path::String)
    res=readchomp(`$ipfscommand files ls -l $(choosepath(path))`)
    MFSfile(res)
end
function MFSblock(name::String,
    cid::AbstractString,
    Size::AbstractString,
    CumulativeSize::AbstractString,
    ChildBlocks::AbstractString,
    MFStype::AbstractString)
    MFSblock(MFSfile(name,cid,parseint(Size)),parseint(CumulativeSize),parseint(ChildBlocks),MFStype)
    
end
function MFSblock(name::String,res::AbstractString)
    res=split(res, "\n")
    MFSblock(name,res[1],map(x->split(x,": ")[2],res[2:end])...)
end
function stat(path::String)
    res=readchomp(`$ipfscommand files stat $(choosepath(path))`)
    MFSblock(basename(path),res)
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
    if !quiet
        push!(cmdhead,"--quiet=false")
    end
    if !pin
        push!(cmdhead,"--pin=false")
    end
    cmdhead
end
function add(file::String;recursive::Bool=false,progress::Bool=true,quiet::Bool=false,
    pin::Bool=false,addReference::Bool=true)
    cmdhead=_add(file;recursive,progress,quiet,pin)
    if addReference
        push!(cmdhead,"--to-files",pwd)
    end
    res=read(Cmd(cmdhead))
    # String(res[7:52])
    String(res)
end
function add(file::String,path::String;recursive::Bool=false,progress::Bool=true,quiet::Bool=false,
    pin::Bool=false,addReference::Bool=true)
    cmdhead=_add(file;recursive,progress,quiet,pin)
    if addReference
        push!(cmdhead,"--to-files",choosepath(path))
    end
    res=read(Cmd(cmdhead))
    # String(res[7:52])
    String(res)
end

macro ipfs_str(expr)
    elem=split(expr).|>String
    :($(Symbol(elem[1]))($(elem[2:end]...)))
end