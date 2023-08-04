export Timeout,timeout
@kwdef struct Timeout
    num::Integer
    unit::String
end

TIMEOUT::Timeout=Timeout(10,"s")

function Base.string(s::Timeout)
    _timeout=string(s.num)*s.unit
    "--timeout="*_timeout
end
Base.convert(::Type{String},s::Timeout)=string(s)
function timeout(num::Integer,unit::String="s")
    global TIMEOUT=Timeout(num,unit)
end