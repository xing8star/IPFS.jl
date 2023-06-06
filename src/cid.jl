function stat(mfs::MFS)
    readchomp(`$ipfscommand block stat $(getcid(mfs))`)
end

function get(ref::String;output::Union{Nothing,String}=nothing,compress::Bool=false,archive::Bool=compress,clevel::Int=5,
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
        push!(cmdhead,"--output=$output")
    end
    push!(cmdhead,ref)
    run(Cmd(cmdhead))
end
get(cid::MFS;output=nothing,kwargs...)=get(getcid(cid);output=isnothing(output) ? getname(cid) : output,
    kwargs...)

function base32(cid::String)
    readchomp(`$ipfscommand cid base32 $cid`)
end
base32(cid::MFS)=base32(getcid(cid))