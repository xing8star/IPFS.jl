module MyTools
export @delegate_onefield,
        determinecommand
macro delegate_onefield(sourceType, sourcefield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    fieldname  = esc(Expr(:quote, sourcefield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs)
    for (i,(funcnames)) in enumerate(targetedFuncs.args)
        funcname = esc(funcnames)
        fdefs[i] = quote
                     ($funcname)(a::($typesname)) =
                       ($funcname)(getproperty(a,Symbol($fieldname)))
                   end
    end
    Expr(:block, fdefs...)
end


function determinecommand(mainname::String)
    if Sys.islinux()
        mainname
    elseif Sys.iswindows()
        mainname*".exe"
    end
end
parseint(s)=parse(Int,s)
end