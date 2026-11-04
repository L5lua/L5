# L5 Examples

Each folder in this directory is an L5 example.

To proceed with running examples, you need to have already:
1. Installed [LÖVE](https://love2d.org/wiki/love)
2. Learned how to run shell commands in a terminal emulator
3. Cloned this git repository to a folder on your computer

Once you have the preliminaries taken care of, in a terminal shell:

1. Change your working directory to the top level of this git repo:
   ```
   cd path/to/wherever/you/cloned/L5
   ```

2. To run the clock example:
   ```
   love examples/clock
   ```

3. To run other examples, follow the pattern: `love examples/whatever`

3. There's also a bash script, [run-all-examples.sh](../run-all-examples.sh) to run all the examples in order. This is meant as a quick way to get a sense of what's possible and to test whether things are working as expected. If you want to modify `L5.lua`, running the examples is a way you can test if things still work correctly after your changes. To use the script:

   ```
   cd path/to/wherever/you/cloned/L5
   ./run-all-examples.sh
   ```

   Initially, the script will run the first example. When you close the window for that example, the script will show a prompt asking if you want to continue. You can answer yes by typing the `Enter` or `Return` key. In that case, the script will run the next example. Alternately, to quit, press the `q` key.

   Note that this script depends on the bash shell's built in `read` command and its `-n 1` option to read just one character at a time. If your computer does not provide the `bash` shell, the script may not work properly.


## Nuance Around `require("L5")`

Each example includes a `require("L5")` line near the top to tell the LÖVE game engine that your sketch is meant to use the L5 library. In order for LÖVE to find the `L5.lua` file, you need to do one of:

- Put a copy of `L5.lua` in the same folder as your `main.lua` file
- Modify Lua's `package.path` global variable to tell Lua where to find L5

The examples here all take the second approach, modifying `package.path` so they can share the single [L5.lua](../L5.lua) file at the top level of this git repository. The alternative would be to maintain copies of `L5.lua` in each example directory, which would interfere with making edits to the library itself.

If you want to make your own sketch based on one of the examples, and if you want to eventually share that with other people as a `.love` game archive, you should follow a different procedure:

1. Make a copy of `L5.lua` and put it in the folder for your sketch, next to `main.lua`

2. Read the LÖVE [Game Distribution](https://love2d.org/wiki/Game_Distribution) wiki page to understand how sharing LÖVE games works (making `.love` files with `zip`, etc)

3. [Optional] you can remove the `package.path = ...` code that the examples include above `require("L5")`. The examples need that because they don't have their own copy of `L5.lua`. If you include `L5.lua` in your sketch's folder, changing the path isn't necessary.
