<div align="center">
<img src="https://github.com/ChifiSource/image_dump/blob/main/olive/olivesession.png" width="250"></img>
</div>

###### collaborative notebooks for julia!
The `OliveSession` module is an [Olive](https://github.com/ChifiSource/Olive.jl) extension that provides Olive with better multi-user support. This culminates in a few different ways. \
\
To add this module, simply add it to your `olive` home environment and then add `using OliveSession` to your `olive` home file. [Olive](https://github.com/ChifiSource/Olive.jl#installing-extensions)
**Random**
- new `create` function for creating [Olive](https://github.com/ChifiSource/Olive.jl) servers as [Toolips](https://github.com/ChifiSource/Toolips.jl)
**File Sharing**
- There is a new `cell_bind!` method which will bind cells with RPC whenever a `Project{:rpc}` is built with it.
- There is a new `cell_highlight` function which adds a cursor indicator for each user.
- There is a new send page icon in the top left which allows for files to be shared.
---
#### (everything beyond this point is TODO)
- There are new (synched) `:creator` cells.
- There is a new way to share projects in readonly mode, alongside the new `Project{:readonly}`

**Directories**
- There are new sharable directories with different permission options.
- The option to create a module for each client -- providing each user with the ability to load their **own** extensions and `olive` home file. (Their own home directories under `public`)
**Authentication**
- Login passthroughs for olive keys. (landings, logins, etc.)
- (**future**) [ToolipsORM](https://github.com/ChifiSource/ToolipsORM.jl)
