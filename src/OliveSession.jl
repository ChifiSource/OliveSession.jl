module OliveSession
import Olive: build
using Olive.Toolips
using Olive: ToolipsMarkdown
using Olive.ToolipsSession

function build(c::Connection, om::OliveModifier, oe::OliveExtension{:invite})
    ico = Olive.topbar_icon("sessionbttn", "send")
    on(c, ico, "click") do cm::ComponentModifier
        newdiv = div("sessdiv")
        xbutton = button("closesess", text = "X")
        on(c, xbutton, "click") do cm2::ComponentModifier
            style!(cm2, newdiv, "height" => 0percent, "opacity" => 0percent)
        end
        style!(xbutton, "border-radius" => 2px, "background-color" => "red", 
        "font-weight" => "bold", "color" => "white")
        style!(newdiv, "height" => 0percent, "opacity" => 0percent, 
        "transition" => 1seconds)
        style!(cm, newdiv, "height" => 100percent, "opacity" => 100percent)
        push!(newdiv, xbutton)
        insert!(cm, "olivemain", 2, newdiv)
    end
    append!(om, "rightmenu", ico)
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:rpccode},
    cells::Vector{Cell}, proj::Project{<:Any})
    windowname::String = proj.id
    tm = ToolipsMarkdown.TextStyleModifier(cell.source)
    ToolipsMarkdown.julia_block!(tm)
    builtcell::Component{:div} = build_base_cell(c, cm, cell, cells,
    proj, sidebox = true, highlight = true)
    km = rpc_bind!(c, cell, cells, proj)
    interior = builtcell[:children]["cellinterior$(cell.id)"]
    inp = interior[:children]["cellinput$(cell.id)"]
    inp[:children]["cellhighlight$(cell.id)"][:text] = string(tm)
    bind!(c, cm, inp[:children]["cell$(cell.id)"], km, on = :down)
    builtcell::Component{:div}
end

function rpc_bind!(c::Connection, cell::Component{<:Any}, 
    cells::Vector{Cell}, proj::Project{<:Any})

end

function build(c::Connection, cm::ComponentModifier, p::Project{:client})

end
end # module OliveSession
