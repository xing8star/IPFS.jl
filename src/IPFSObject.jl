export AbstractIPFSObject,
IPFSObject,
AbstractIPFSBlock,
Block,Codecs

abstract type AbstractIPFSBlock end
abstract type AbstractIPFSObject <:AbstractIPFSBlock end
abstract type AbstractCIDs end

struct IPFSObject <: AbstractIPFSObject
    cid::String
end
@enum Codecs begin
    raw
    json
end

struct CIDv1 <: AbstractCIDs
    cid::String
end
struct CIDv0 <: AbstractCIDs
    cid::String
end
cid(s::AbstractCIDs)=s.cid

struct Block{Codecs}
    cid::CIDv1
end
cid(s::Block)=cid(s)

cid(s::IPFSObject)=s.cid
hash(s::IPFSObject)=s.cid
IPFSObject(s::AbstractIPFSObject)=IPFSObject(cid(s))