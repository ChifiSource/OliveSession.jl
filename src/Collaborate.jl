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

function build_collab_preview(c::Connection, cm::ComponentModifier, cell::Cell{:collab}, proj::Project{<:Any}, fweight ...)
    first_person::Bool = true
    [begin
        name_color_perm = split(person, "|")
        name = string(name_color_perm[1])
        connected = string(name_color_perm[2])
        perm = string(name_color_perm[3])
        color = string(name_color_perm[4])
        personbox = div("$(name)collab")
        nametag = a("$(name)tag", text = name)
        style!(nametag, "background-color" => color, "color" => "white", "border-radius" => 0px, "width" => 30percent,
        fweight ...)
        style!(personbox, "display" => "flex", "padding" => 0px, "border-radius" => 0px, 
        "min-width" => 100percent, "flex-direction" => "row", "overflow" => "hidden")
        permtag = a("$(name)permtag", text = perm)
        connected = a("$(name)connected")
        if connected == "no"
            style!(connected, "background-color" => "darkred", "color" => "white", "width" => 40percent, fweight ...)
            connected[:text] = "not connected"
        else
            style!(connected, "background-color" => "darkgreen", "color" => "white", "width" => 40percent, fweight ...)
            connected[:text] = "connected"
        end
        if perm == "all"
            style!(permtag, "background-color" => "#301934", "color" => "white", fweight ...)
        elseif perm == "askall"
            style!(perm, "background-color" => "darkblue", "color" => "white", fweight ...)
        elseif perm == "view"
            style!(perm, "background-color" => "darkgray", "color" => "white", fweight ...)
        elseif perm == "askswitch"
            style!(permtag, "background-color" => "darkred", "color" => "white", fweight ...)
        end
        style!(permtag, "width" => 20percent)
        if first_person
            style!(nametag, "border-top-left-radius" => 5px)
            first_person = false
        end
        personbox[:children] = [nametag, permtag, connected]
        if proj.data[:ishost]
            editbox = Olive.topbar_icon("$(name)edit", "app_registration")
            linkbox = Olive.topbar_icon("$(name)link", "link")
            personkey = findfirst(k -> contains(name, k[2]),c[:OliveCore].client_keys)
            linkbox["onclick"] = "\"navigator.clipboard.writeText('https://$(c.hostname)?key=$personkey');\""
            editbox[:align], linkbox[:align] = "center", "center"
            style!(editbox, "background-color" => "darkorange", "color" => "white", "color" => "white", "width" => 5percent, 
            fweight ...)
            style!(linkbox, "background-color" => "#18191A", "color" => "white", "color" => "white", "width" => 5percent, 
            fweight ...)
            push!(personbox, editbox, linkbox)
        end
        personbox::Component{:div}
    end for person in split(cell.outputs, ";")]
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
    style!(addbox, "background-color" => "darkorange", "color" => "white", "width" => 10percent, fweight ...)
    add_person[:children] = [nametag, perm_container, colorcont, addbox]
    add_person
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:collab}, proj::Project{<:Any})
    outercell::Component{:div} = div("cellcontainer$(cell.id)")
    # on initial creation, propagates this value.
    if ~(:active in keys(proj.data))
        proj.data[:active] = false
    end
    is_active::Bool = proj.data[:active]
    # check if rpc is open
    if is_active
        # if peer
        if ~(proj.data[:ishost])
            join_rpc!(c, cm, proj.data[:host], tickrate = 120)
            call!(cm) do cmcall::ComponentModifier
                splits = split(cell.outputs, ";")
                ind = findfirst(n -> split(n, "|")[1] == getname(c), splits)
                data = splits[ind]
                color = split(data, "|")[4]
                olive_notify!(cm, "$(getname(c)) has joined !", color = color)
            end
        # if host
        else

        end
    else
     #   poweronbutton = Olive.topbar_icon("openrpcbutt", text = "open")
      #  style!(poweronbutton, "font-size" => 13pt)
    end
    # collaborators box
    collab_status = div("colabstatus")
    style!(collab_status, "display" => "flex", "flex-direction" => "column", 
    "padding" => 0px, "border-radius" => 0px, "align-content" => "center", "width" => 50percent, 
    "height" => 40percent)
    fweight = ("font-weight" => "bold", "font-size" => 14pt, "padding" => 5px)
    people = build_collab_preview(c, cm, cell, proj, fweight ...)
    collab_status[:children] = people
    if proj.data[:ishost]
        add_person = build_collab_edit(c, cm, cell, proj, fweight ...)
        push!(collab_status, add_person)
    else
        lastch = people[length(people)]
        style!(lastch, "border-bottom-left-radius" => 5px, "border-bottom-right-radius" => 5px)
    end
    push!(outercell, collab_status)
 #==   invutton = button("invitesess", text = "invite")
    on(c, invutton, "click") do cm2::ComponentModifier
        if 
        projs = c[:OliveCore].open[Olive.getname(c)].projects
        proj.data[:active] = true
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
        [Olive.close_project(c, cm2, pro) for pro in projs]
        c[:OliveCore].open[Olive.getname(c)].projects = hostprojs
        [Olive.open_project(c, cm2, pro, build_tab(c, pro)) for pro in hostprojs]
        proj.data[:host] = getname(c)
        nametext = cm2[nameenter]["text"]
        key = ToolipsSession.gen_ref(4)
        push!(c[:OliveCore].client_keys, key => nametext)
        env::Environment = Environment(nametext)
        env.directories = c[:OliveCore].open[Olive.getname(c)].directories
        env.projects = clientprojs
        push!(c[:OliveCore].client_data, nametext => Dict{String, Any}())
        push!(c[:OliveCore].open, env)
        alert!(cm2, key)
        open_rpc!(c, cm2, Olive.getname(c), tickrate = 120)
    end ==#
   # nameenter = ToolipsDefaults.textdiv("nameinvite")
    #push!(outercell, invutton, nameenter)
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

function build(c::Connection, cm::ComponentModifier, p::Project{:rpc})
    proj_window::Component{:div} = div(p.id)
    style!(proj_window, "overflow-y" => "scroll", "overflow-x" => "hidden")
    if p.data[:ishost]
        frstcells::Vector{Cell} = p[:cells]
    else
        frstcells = c[:OliveCore].open[p.data[:host]][p.name][:cells]
    end
    retvs = Vector{Servable}([begin
        Base.invokelatest(c[:OliveCore].olmod.build, c, cm, cell,
        frstcells, p)::Component{<:Any}
    end for cell in frstcells])
    proj_window[:children] = retvs
    proj_window::Component{:div}
end

#==function build_tab(c::Connection, p::Project{:rpc}; hidden::Bool = false)

end==#

function cell_bind!(c::Connection, cell::Cell{<:Any}, proj::Project{:rpc})
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

function cell_highlight!(c::Connection, cm::ComponentModifier, cell::Cell{:code}, proj::Project{:rpc})
    windowname::String = proj.id
    curr = cm["cell$(cell.id)"]["text"]
    curr_raw = cm["rawcell$(cell.id)"]["text"]
    if curr_raw == "]"
        remove!(cm, "cellcontainer$(cell.id)")
        pos = findfirst(lcell -> lcell.id == cell.id, cells)
        new_cell = Cell(pos, "pkgrepl", "")
        deleteat!(cells, pos)
        insert!(cells, pos, new_cell)
        ToolipsSession.insert!(cm, windowname, pos, build(c, cm, new_cell,
         cells, proj))
         focus!(cm, "cell$(new_cell.id)")
    elseif curr_raw == ";"
        remove!(cm, "cellcontainer$(cell.id)")
        pos = findfirst(lcell -> lcell.id == cell.id, cells)
        new_cell = Cell(pos, "shell", "")
        deleteat!(cells, pos)
        insert!(cells, pos, new_cell)
        ToolipsSession.insert!(cm, windowname, pos, build(c, cm, new_cell,
         cells, proj))
         focus!(cm, "cell$(new_cell.id)")
    elseif curr_raw == "?"
        pos = findfirst(lcell -> lcell.id == cell.id, cells)
        new_cell = Cell(pos, "helprepl", "")
        deleteat!(cells, pos)
        insert!(cells, pos, new_cell)
        remove!(cm, "cellcontainer$(cell.id)")
        ToolipsSession.insert!(cm, windowname, pos, build(c, cm, new_cell,
         cells, proj))
        focus!(cm, "cell$(new_cell.id)")
    elseif curr_raw == "#=TODO"
        remove!(cm, "cellcontainer$(cell.id)")
        pos = findfirst(lcell -> lcell.id == cell.id, cells)
        new_cell = Cell(pos, "TODO", "")
        deleteat!(cells, pos)
        insert!(cells, pos, new_cell)
        ToolipsSession.insert!(cm, windowname, pos, build(c, cm, new_cell,
         cells, proj))
         focus!(cm, "cell$(new_cell.id)")
    elseif curr_raw == "#=NOTE"
        pos = findfirst(lcell -> lcell.id == cell.id, cells)
        new_cell = Cell(pos, "NOTE", "")
        deleteat!(cells, pos)
        insert!(cells, pos, new_cell)
        remove!(cm, "cellcontainer$(cell.id)")
        ToolipsSession.insert!(cm, windowname, pos, build(c, cm, new_cell,
         cells, proj))
        focus!(cm, "cell$(new_cell.id)")
    elseif curr_raw == "include("
        pos = findfirst(lcell -> lcell.id == cell.id, cells)
        new_cell = Cell(pos, "include", cells[pos].source, cells[pos].outputs)
        deleteat!(cells, pos)
        insert!(cells, pos, new_cell)
        remove!(cm, "cellcontainer$(cell.id)")
        ToolipsSession.insert!(cm, windowname, pos, build(c, cm, new_cell,
         cells, proj))
        focus!(cm, "cell$(new_cell.id)")
    end
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
    ToolipsSession.call!(c) do cm2::ComponentModifier
        hltxt = first_half * "<a style='color:lightblue;'>▆</a>" * second_half
        set_text!(cm2, "cellhighlight$(cell.id)", string(tm))
    end 
    ==#
end

function build_base_input(c::Connection, cm::ComponentModifier, cell::Cell{<:Any}, proj::Project{:rpc}; highlight::Bool = false)
    windowname::String = proj.id
    inputbox::Component{:div} = div("cellinput$(cell.id)")
    inside::Component{:div} = ToolipsDefaults.textdiv("cell$(cell.id)",
    text = replace(cell.source, "\n" => "</br>", " " => "&nbsp;"),
    "class" => "input_cell")
    style!(inside, "border-top-left-radius" => 0px)
    if highlight
        highlight_box::Component{:div} = div("cellhighlight$(cell.id)",
        text = "hl")
        style!(highlight_box, "position" => "absolute",
        "background" => "transparent", "z-index" => "5", "padding" => 20px,
        "border-top-left-radius" => "0px !important",
        "border-radius" => "0px !important", "line-height" => 15px,
        "max-width" => 90percent, "border-width" =>  0px,  "pointer-events" => "none",
        "color" => "#4C4646 !important", "border-radius" => 0px, "font-size" => 13pt, "letter-spacing" => 1px,
        "font-family" => """"Lucida Console", "Courier New", monospace;""", "line-height" => 24px)
        on(c, inputbox, "keyup", ["cell$(cell.id)", "rawcell$(cell.id)"]) do cm2::ComponentModifier
            cell_highlight!(c, cm2, cell, cells, proj)
        end
        on(cm, inputbox, "paste") do cl
            push!(cl.changes, """
            e.preventDefault();
            var text = e.clipboardData.getData('text/plain');
            document.execCommand('insertText', false, text);
            """)
        end
        push!(inputbox, highlight_box, inside)
    else
        on(c, inside, "keypress") do cm2::ComponentModifier

        end
        push!(inputbox, inside)
    end
    on(c, inside, "focus") do cm2::ComponentModifier
        call!(c) do cm3::ComponentModifier
            style!(cm3, inside, "border-width" => 2px, "border-style" => "solid", "border-color" => "blue")
            cm3[inside] = "contenteditable" => "false"
        end
    end
    on(c, inside, "focusout") do cm2::ComponentModifier
        call!(c) do cm3::ComponentModifier
            style!(cm3, inside, "border-width" => 0px, "border-color" => "gray")
            cm3[inside] = "contenteditable" => "true"
        end
    end
    inputbox::Component{:div}
end

end # - module !