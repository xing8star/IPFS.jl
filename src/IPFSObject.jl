export AbstractIPFSObject,
IPFSObject

abstract type AbstractIPFSObject end
struct IPFSObject <: AbstractIPFSObject
    cid::String
end
cid(s::IPFSObject)=s.cid
IPFSObject(s::AbstractIPFSObject)=IPFSObject(cid(s))