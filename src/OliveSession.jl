module OliveSession
using Olive
using Olive.Toolips
using Olive: ToolipsMarkdown
using Olive.ToolipsSession
using Olive.ToolipsDefaults
using Olive: OliveExtension, Project, Cell, OliveModifier, Environment
import Olive: build, cell_bind!
function build(c::Connection, om::OliveModifier, oe::OliveExtension{:invite})
    ico = Olive.topbar_icon("sessionbttn", "send")
    on(c, ico, "click") do cm::ComponentModifier
        newdiv = div("sessdiv")
        xbutton = button("closesess", text = "X")
        invutton = button("invitesess", text = "invite")
        nameenter = ToolipsDefaults.textdiv("nameinvite")
        on(c, invutton, "click") do cm2::ComponentModifier
            projs = c[:OliveCore].open[Olive.getname(c)].projects
            hostprojs = [begin 
                np = Project{:rpc}(p.name)
                np.data = p.data
                push!(np.data, :ishost => true)
                np::Project{:rpc}
            end for p in projs]
            clientprojs = [begin 
            np = Project{:rpc}(p.name)
            push!(np.data, :ishost => false, :host => Olive.getname(c), 
            :pane => p.data[:pane])
            np::Project{:rpc}
            end for p in projs]
            c[:OliveCore].open[Olive.getname(c)].projects = hostprojs
            nametext = cm2[nameenter]["text"]
            key = ToolipsSession.gen_ref(4)
            push!(c[:OliveCore].client_keys, key => nametext)
            env::Environment = Environment(nametext)
            env.projects = clientprojs
            push!(c[:OliveCore].client_data, nametext => Dict{String, Any}())
            push!(c[:OliveCore].open, env)
            alert!(cm2, key)
            redirect!(cm2, "/")
        end
        on(c, xbutton, "click") do cm2::ComponentModifier
            style!(cm2, newdiv, "height" => 0percent, "opacity" => 0percent)
        end
        style!(xbutton, "border-radius" => 2px, "background-color" => "red", 
        "font-weight" => "bold", "color" => "white")
        push!(newdiv, nameenter, invutton, xbutton)
        insert!(cm, "olivemain", 2, newdiv)
    end
    append!(om, "rightmenu", ico)
end

function cell_bind!(c::Connection, cell::Cell{<:Any}, 
    cells::Vector{Cell}, proj::Project{:rpc})
    keybindings = c[:OliveCore].client_data[Olive.getname(c)]["keybindings"]
    km = ToolipsSession.KeyMap()
    bind!(km, keybindings["save"], prevent_default = true) do cm::ComponentModifier
        Olive.save_project(c, cm, proj)
        rpc!(c, cm)
    end
    bind!(km, keybindings["up"]) do cm2::ComponentModifier
        Olive.cell_up!(c, cm2, cell, cells, proj)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["down"]) do cm2::ComponentModifier
        Olive.cell_down!(c, cm2, cell, cells, proj)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["delete"]) do cm2::ComponentModifier
        Olive.cell_delete!(c, cm2, cell, cells)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["evaluate"]) do cm2::ComponentModifier
        Olive.evaluate(c, cm2, cell, cells, proj)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["new"]) do cm2::ComponentModifier
        Olive.cell_new!(c, cm2, cell, cells, proj)
    end
    bind!(km, keybindings["focusup"]) do cm::ComponentModifier
        Olive.focus_up!(c, cm, cell, cells, proj)
    end
    bind!(km, keybindings["focusdown"]) do cm::ComponentModifier
        Olive.focus_down!(c, cm, cell, cells, proj)
    end
    km::KeyMap
end

function build(c::Connection, cm::ComponentModifier, p::Project{:rpc})
    proj_window::Component{:div} = div(p.id)
    style!(proj_window, "overflow-y" => "scroll", "overflow-x" => "hidden")
    if p.data[:ishost]
        frstcells::Vector{Cell} = p[:cells]
        open_rpc!(c, cm, Olive.getname(c))
    else
        join_rpc!(c, cm, p.data[:host])
        frstcells = c[:OliveCore].open[p.data[:host]][p.name][:cells]
    end
    retvs = Vector{Servable}([begin
        Base.invokelatest(c[:OliveCore].olmod.build, c, cm, cell,
        frstcells, p)::Component{<:Any}
    end for cell in frstcells])
    proj_window[:children] = retvs
    proj_window::Component{:div}
end

end # module OliveSession
