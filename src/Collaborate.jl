module Collaborate
using Olive
using Olive.Toolips
using Olive: ToolipsMarkdown
using Olive.ToolipsSession
using Olive.ToolipsDefaults
using Olive: OliveExtension, Project, Cell, OliveModifier, Environment, getname
import Olive: build, cell_bind!, cell_highlight!, build_base_input, build_tab

function build(c::Connection, om::OliveModifier, oe::OliveExtension{:invite})
    ico = Olive.topbar_icon("sessionbttn", "send")
    on(c, ico, "click") do cm::ComponentModifier
        cells = Vector{Cell}([
        Cell(1, "collab", " ","$(getname(c))|no|all|#e75480")])
        home_direc = c[:OliveCore].data["home"] * "hi"
        projdict = Dict{Symbol, Any}(:cells => cells, :env => c[:OliveCore].data["home"],
        :ishost => true)
        inclproj = Project{:collab}("collaborators", projdict)
        push!(c[:OliveCore].open[getname(c)].projects, inclproj)
        tab = build_tab(c, inclproj)
        Olive.open_project(c, cm, inclproj, tab)
    end
    append!(om, "rightmenu", ico)
end
#==
rpcinfo
==#

function build_collab_preview(c::Connection, cm::ComponentModifier, source::String, proj::Project{<:Any}, fweight ...; 
    ignorefirst::Bool = false)
    first_person::Bool = true
    [begin
        name_color_perm = split(person, "|")
        name = string(name_color_perm[1])
        connect = string(name_color_perm[2])
        perm = string(name_color_perm[3])
        color = string(name_color_perm[4])
        personbox = div("$(name)collab")
        nametag = a("$(name)tag", text = name)
        style!(nametag, "background-color" => color, "color" => "white", "border-radius" => 0px, "width" => 30percent,
        fweight ...)
        n = getname(c)
        personkey = string(findfirst(k -> name == k, c[:OliveCore].client_keys))
        style!(personbox, "display" => "flex", "padding" => 0px, "border-radius" => 0px, 
        "min-width" => 100percent, "flex-direction" => "row", "overflow" => "hidden")
        permtag = a("$(name)permtag", text = perm)
        connected = a("$(name)connected", href = "'https://$(c.hostname)/?key=$personkey'")
        if contains("yes", connect)
            style!(connected, "background-color" => "darkgreen", "color" => "white", "width" => 40percent, fweight ...)
            connected[:text] = "connected"
        else
            style!(connected, "background-color" => "darkred", "color" => "white", "width" => 40percent, fweight ...)
            connected[:text] = "not connected"
        end
        if perm == "all"
            style!(permtag, "background-color" => "#301934", "color" => "white", fweight ...)
        elseif perm == "askall"
            style!(permtag, "background-color" => "darkblue", "color" => "white", fweight ...)
        elseif perm == "view"
            style!(permtag, "background-color" => "darkgray", "color" => "white", fweight ...)
        elseif perm == "askswitch"
            style!(permtag, "background-color" => "darkred", "color" => "white", fweight ...)
        end
        style!(permtag, "width" => 20percent)
        if first_person && ~(ignorefirst)
            style!(nametag, "border-top-left-radius" => 5px)
            first_person = false
        end
        personbox[:children] = [nametag, permtag, connected]
        if proj.data[:ishost]
            editbox = Olive.topbar_icon("$(name)edit", "app_registration")
            linkbox = Olive.topbar_icon("$(name)link", "link")
            on(c, linkbox, "click") do cm2::ComponentModifier
                push!(cm2.changes, "navigator.clipboard.writeText('https://$(c.hostname)/?key=$personkey');")
                Olive.olive_notify!(cm2, "link for $name copied to clipboard", color = color)
            end
            editbox[:align], linkbox[:align] = "center", "center"
            style!(editbox, "background-color" => "darkorange", "color" => "white", "color" => "white", "width" => 5percent, 
            fweight ...)
            style!(linkbox, "background-color" => "#18191A", "color" => "white", "color" => "white", "width" => 5percent, 
            fweight ...)
            push!(personbox, editbox, linkbox)
        end
        personbox::Component{:div}
    end for person in split(source, ";")]
end

function build_collab_edit(c::Connection, cm::ComponentModifier, cell::Cell{:collab}, proj::Project{<:Any}, fweight ...)
    add_person = div("addcollab")
    style!(add_person, "padding" => 0px, "border-radius" => 0px, "display" => "flex", "min-width" => 100percent, 
    "border-bottom-left-radius" => 5px, "border-bottom-right-radius" => 5px, "flex-direction" => "row", "overflow" => "hidden")
    nametag = a("addname", text = "", contenteditable = true)
    style!(nametag, "background-color" => "#18191A", "color" => "white", "border-radius" => 0px, 
    "width" => 30percent, "line-clamp" =>"1", "overflow" => "hidden", "display" => "-webkit-box", fweight ...)
    perm_opts = Vector{Servable}(
        [ToolipsDefaults.option(opt, text = opt) for opt in ["all", "askall", "view", "askswitch"]]
    )
    perm_selector = ToolipsDefaults.dropdown("permcollab", perm_opts)
    perm_selector[:value] = "all"
    style!(perm_selector, "height" => 100percent, "width" => 100percent)
    perm_container = a("permcont", align = "center")
    style!(perm_container, "width" => 20percent,  "background-color" => "#242526", fweight ...)
    push!(perm_container, perm_selector)
    color_selector = ToolipsDefaults.colorinput("colorcollab", value = "#498437")
    style!(color_selector, "-webkit-appearance" => "none", "moz-appearance" => "none", "appearance" => "none", 
    "background-color" => "transparent", "pointer" => "cursor", "width" => 100percent, "height" => 100percent, "border" => "none")
    colorcont = a("colorcont", align = "center")
    push!(colorcont, color_selector)
    style!(colorcont, "background-color" => "#242526", "width" => 40percent, fweight ...)
    addbox = Olive.topbar_icon("collabadder", "add_box")
    addbox[:align] = "center"
    ol_user::String = getname(c)
    on(c, addbox, "click") do cm2::ComponentModifier
        name = cm2[nametag]["text"]
        if name == ""
            Olive.olive_notify!(cm2, "you must name a new collaborator", color = "red")
            return
        elseif ~(proj[:active])
            Olive.olive_notify!(cm2, "cannot add to inactive session !", color = "red")
            return
        end
        perm = cm2[perm_selector]["value"]
        colr = cm2[color_selector]["value"]
        pers = "$name|no|$perm|$colr"
        cell.outputs = cell.outputs * ";$pers"
        projs = c[:OliveCore].open[Olive.getname(c)].projects
        key = ToolipsSession.gen_ref(4)
        push!(c[:OliveCore].client_keys, key => name)
        env::Environment = Environment(name)
        env.pwd = c[:OliveCore].open[getname(c)].pwd
        env.directories = c[:OliveCore].open[Olive.getname(c)].directories
        [begin
        np = Project{:rpc}(p.name)
        np.data = p.data
        np.data[:host] = ol_user
        np.id = p.id
        push!(env.projects, np)
    end for p in filter(d -> ~(d.id == proj.id), projs)]
        newcollab = Project{:collab}(proj.name)
        newcollab.data = copy(proj.data)
        newcollab.data[:ishost] = false
        push!(env.projects, newcollab)
        push!(c[:OliveCore].client_data, name => Dict{String, Any}())
        push!(c[:OliveCore].open, env)
        box = build_collab_preview(c, cm2, pers, proj, ignorefirst = true, fweight ...)
        insert!(cm2, "colabstatus", 2, box[1])
        Olive.olive_notify!(cm2, "collaborator $name added to session", color = colr)
    end
    style!(addbox, "background-color" => "darkorange", "color" => "white", "width" => 5percent, fweight ...)
    poweron = Olive.topbar_icon("collabon", "power_settings_new")
    poweron[:align] = "center"
    on(c, poweron, "click") do cm2::ComponentModifier
        projs = c[:OliveCore].open[Olive.getname(c)].projects
        hostprojs = Vector{Olive.Project{<:Any}}(filter!(d -> ~(d.id == proj.id), [begin
            np = Project{:rpc}(p.name)
            np.data = p.data
            np.data[:host] = ol_user
            np.id = p.id
            np::Project{:rpc}
        end for p in projs]))
        [Olive.close_project(c, cm2, pro) for pro in projs]
        c[:OliveCore].open[Olive.getname(c)].projects = hostprojs
        [Olive.open_project(c, cm2, pro, build_tab(c, pro)) for pro in hostprojs]
        push!(hostprojs, proj)
        proj.data[:host] = getname(c)
        proj.data[:active] = true
        style!(cm2, poweron, "color" => "green")
        open_rpc!(c, cm2, Olive.getname(c), tickrate = 120)
        Olive.olive_notify!(cm2, "collaborative session now active")
    end
    if proj[:active]
        powerbg = "lightgreen"
    else
       powerbg = "white"
    end
    style!(poweron, "background-color" => "#242526", "color" => powerbg, "width" => 5percent, fweight ...)
    add_person[:children] = [nametag, perm_container, colorcont, addbox, poweron]
    add_person
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:collab}, proj::Project{<:Any})
    # on initial creation, propagates this value.
    if ~(:active in keys(proj.data))
        proj.data[:active] = false
    end
    is_active::Bool = proj.data[:active]
    # check if rpc is open
    if is_active
        # if peer
        if ~(proj[:ishost])
            join_rpc!(c, cm, proj.data[:host])
            splits = split(cell.outputs, ";")
            ind = findfirst(n -> split(n, "|")[1] == getname(c), splits)
            data = splits[ind]
            color = split(data, "|")[4]
            Olive.olive_notify!(cm, "$(getname(c)) has joined !", color = string(color))
            call!(c, cm)
        # if host
        else

        end
    end
    outercell::Component{:div} = div("cellcontainer$(cell.id)")
    # move onto building the cell
    # collaborators box
    collab_status = div("colabstatus")
    style!(collab_status, "display" => "flex", "flex-direction" => "column", 
    "padding" => 0px, "border-radius" => 0px, "align-content" => "center", "width" => 50percent, 
    "height" => 40percent)
    fweight = ("font-weight" => "bold", "font-size" => 14pt, "padding" => 5px)
    people = build_collab_preview(c, cm, cell.outputs, proj, fweight ...)
    collab_status[:children] = people
    if proj.data[:ishost]
        add_person = build_collab_edit(c, cm, cell, proj, fweight ...)
        push!(collab_status, add_person)
    else
        lastch = people[length(people)]
        style!(lastch, "border-bottom-left-radius" => 5px, "border-bottom-right-radius" => 5px)
    end
    push!(outercell, collab_status)
    outercell::Component{:div}
end

#==
rpc projects
==#

#== TODO
slightly redesign this -- this function will become the `collaborators` project's 
`build` function. Along with the tab below it. (this way `join/open_rpc!` only 
    gets called once.) 
==#

#==function build_tab(c::Connection, p::Project{:rpc}; hidden::Bool = false)

end==#

function cell_bind!(c::Connection, cell::Cell{<:Any}, proj::Project{:rpc})
    keybindings = c[:OliveCore].client_data[Olive.getname(c)]["keybindings"]
    km = ToolipsSession.KeyMap()
    cells = proj[:cells]
    bind!(km, keybindings["save"], prevent_default = true) do cm::ComponentModifier
        Olive.save_project(c, cm, proj)
        rpc!(c, cm)
    end
    bind!(km, keybindings["up"]) do cm2::ComponentModifier
        Olive.cell_up!(c, cm2, cell, proj)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["down"]) do cm2::ComponentModifier
        Olive.cell_down!(c, cm2, cell, proj)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["delete"]) do cm2::ComponentModifier
        Olive.cell_delete!(c, cm2, cell, cells)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["evaluate"]) do cm2::ComponentModifier
        Olive.evaluate(c, cm2, cell, proj)
        rpc!(c, cm2)
    end
    bind!(km, keybindings["new"]) do cm2::ComponentModifier
        Olive.cell_new!(c, cm2, cell, proj)
        call!(cm2) do cm3::ComponentModifier

        end
    end
    bind!(km, keybindings["focusup"]) do cm::ComponentModifier
        Olive.focus_up!(c, cm, cell, cells, proj)
    end
    bind!(km, keybindings["focusdown"]) do cm::ComponentModifier
        Olive.focus_down!(c, cm, cell, cells, proj)
    end
    km::KeyMap
end

function get_collaborator_data(c::Connection, proj::Project{:rpc})
    projs = c[:OliveCore].open[proj[:host]].projects
    pf = findfirst(p -> typeof(p) == Project{:rpcinfo}, projs)
    rpcinfo_proj = projs[pf]
    allinfo = rpcinfo_proj[:cells][1].outputs
    splitinfo = split(allinfo, ";")
    just_me = findfirst(s -> contains(split(s, "|")[1], getname(c)))
    split(plitinfo[just_me], "|")::Vector{SubString}
end

function cell_highlight!(c::Connection, cm::ComponentModifier, cell::Cell{:code}, proj::Project{:rpc})
    windowname::String = proj.id
    curr = cm["cell$(cell.id)"]["text"]
    curr_raw = cm["rawcell$(cell.id)"]["text"]
    cursorpos = parse(Int64, cm["cell$(cell.id)"]["caret"])
    cell.source = curr
    if length(cell.source) == 0
        return
    end
    tm = c[:OliveCore].client_data[getname(c)]["highlighters"]["julia"]
    tm.raw = cell.source[1:cursorpos]
    ToolipsMarkdown.mark_julia!(tm)
    first_half = string(tm)
    ToolipsMarkdown.clear!(tm)
    tm.raw = cell.source[cursorpos:length(cell.source)]
    ToolipsMarkdown.mark_julia!(tm)
    second_half = string(tm)
    ToolipsMarkdown.clear!(tm)
    set_text!(cm, "cellhighlight$(cell.id)", string(tm))
    collabdata = get_collaborator_data(c, proj)
    ToolipsSession.call!(c) do cm2::ComponentModifier
        hltxt = first_half * "<a style='color:$(collabdata[4]);'>▆</a>" * second_half
        set_text!(cm2, "cellhighlight$(cell.id)", string(tm))
    end 
end

end # - module !