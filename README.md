## MoonBar

This is my pet project i3bar implementation. It's based on another project of mine: [spook](https://github.com/johnae/spook). Spook started out as a lightweight [guard](https://github.com/guard/guard) but overtime has become
somewhat of an event framework (for unix only). Anyway, I wanted to build something else on spook than just using it as a test runner. This is one such thing.

So, this is basically a very configurable and especially programmable i3bar implementation. It's kind of rough around the edges right now. Coroutines are used in some places for nicer looking code, could be interesting.
Anyway, this might continue to be more of an experiment than anything else. Feel free to use it or do whatever. To run this you must get [spook](https://github.com/johnae/spook). It is programmed in [MoonScript](https://github.com/leafo/moonscript) or [Lua](http://www.lua.org). [spook](https://github.com/johnae/spook) itself embeds the [LuaJIT VM](http://luajit.org/) and [MoonScript](https://github.com/leafo/moonscript) comes built-in.

I run this from i3 like this:

```sh
spook -w /path/to/moonbar
```
### License

MoonBar is released under the MIT license (see [LICENSE.md](LICENSE.md) for details).
