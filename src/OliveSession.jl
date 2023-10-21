"""
Created in February, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
#### OliveSession
OliveSession provides Olive with multi-user functionality, making olive far more 
deployable and sharable.
"""
module OliveSession
using Olive
using Olive.Toolips
using Olive: ToolipsMarkdown
using Olive.ToolipsSession
using Olive.ToolipsDefaults
using Olive: OliveExtension, Project, Cell, OliveModifier, Environment, getname
import Olive: build, cell_bind!, cell_highlight!, build_base_input, build_tab

include("Collaborate.jl")

function route_before_session!(f::Function, os::Toolips.WebServer)
    main = route("/") do c::Connection
        f(c)
        Olive.session(c)
    end
    os["/"] = main
    nothing
end

#==
readonly
==#
function cell_bind!(c::Connection, cell::Cell{<:Any}, proj::Project{:readonly})

end

#==
permissions management
==#
module Permissions

end
#==
Per-client memory limiting
==#
module MemLimit

end

export route_before_session!
end # module OliveSession
