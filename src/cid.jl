function stat(mfs::MFS)
    res=readchomp(`$ipfscommand block stat $(getcid(mfs))`)
end

function get(ref::String)
    run(`$ipfscommand get $ref`)
end
get(cid::MFS)=get(getcid(cid))

function base32(cid::String)
    readchomp(`$ipfscommand cid base32 $cid`)
end
base32(cid::MFS)=base32(getcid(cid))