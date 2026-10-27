#!/usr/bin/env lua
--[[
Run all the L5 examples.

Usage (from a Debian terminal emulator shell):

   lua run-examples.lua

Unless you have uncommitted changes to main.lua, answer "Y" for yes at the
prompt.

To use this script, you need a terminal with a shell (bash, zsh, etc) that
provides `git`, `love`, and `lua` commands in your $PATH. On Debian Linux, if
needed, you can install them by running:

   sudo apt update && sudo apt install git lua5.4 love

--]]

-- Run a shell command, echoing the shell command's output to the console
local function run(cmd)
	local f = io.popen(cmd)
	if f then
		for line in f:lines() do print(line) end
		f:close()
	end
end

-- Prompt for confirmation, exit if answer is not y (for yes)
local function confirm_continue()
	io.write("Continue? [y/N]: ") io.flush()
	local r = io.read()
	if (r ~= "y") and (r ~= "Y") then
		print('If you change your mind, answer "y" next time.')
		os.exit()
	end
end

-- This script has only been tested on Linux.
local r = io.popen("uname")
local s
if r then s = r:read() r:close() end
if s ~= "Linux" then
	print("You seem to be using a non-Linux OS, so this script might fail.")
	confirm_continue()
end

--[[
LÖVE needs the example code to be named main.lua. Some examples are written to
load images from assets/, so main.lua needs to be in the top level of the repo.
That means we need to DESTRUCTIVELY OVERWRITE main.lua! That could vaporize
uncommitted changes. So, before we proceed, confirm it's okay!
--]]
print("Preparing to run L5 examples...")
print("CAUTION: Don't continue if you have uncommitted changes to main.lua!")
confirm_continue()

-- Loop through all the .lua files in examples/
for file in io.popen("ls examples/*.lua"):lines() do
	-- Prompt (pause) with the current .lua filename
	print("===============================================================")
	io.write(">>> Press ENTER to run "..file.." >>> ") io.flush()
	local s = io.read()
	if s=='q' or s=='Q' then break end
	-- Copy current example to ./main.lua and run it with LÖVE
	run("cp "..file.." main.lua; love .")
	print("\n>>> DONE >>>")
end

-- Restore main.lua from the most recent git commit
print("Running `git restore main.lua`...")
run("git restore main.lua")
