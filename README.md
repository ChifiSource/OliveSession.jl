<div align="center">
<img src="https://github.com/ChifiSource/image_dump/blob/main/olive/olivesession.png" width="250"></img>
</div>

###### collaborative notebooks for julia!
The `OliveSession` module is an [Olive](https://github.com/ChifiSource/Olive.jl) extension that provides Olive with better multi-user support. This culminates in a few different ways. \
\
To add this module, simply add it to your `olive` home environment and then add `using OliveSession` to your `olive` home file. [Olive](https://github.com/ChifiSource/Olive.jl#installing-extensions)

---
###### what's inside?
- collaborator (`rpc`) projects. (google-docs like peer editing for olive)
- file and directory permissions
- readonly projects
- per-client memory limiting
- `create` binding for creating deployed server instances of olive

(These are currently planned, this package is not released. Right now most work has been put into RPC.
