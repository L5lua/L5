# L5

An implementation of a Processing-like API in Lua.

Built on the Love2d framework.

## Why?

Lua. It's a dynamic scripting language like Javascript. The language is tiny in terms of bandwidth and in functions. It is easy to learn, works on old hardware, and stable. The syntax is consistently simple, and unlike Javascript, does not change. It is incredibly fast and works really well on desktop from powerful machines to Raspberry Pi. It is perfect for building an interactive installation and letting it run for months, or for a program that you need to integrate with your host OS, or for making games or interactive artworks on the computer. It's really fun to write.

Lua itself is a language with mechanisms but unlike Python, few *batteries*. It isn't "everything and the kitchen sink". Unlike Javascript in the browser, it lacks a built-in canvas element. That's where Love2d comes in.

Love2d (stylized LÖVE) is a framework to build 2d games in Lua. It is free and open-source and works on Mac, Windows, PC, Android and iOS. Building L5 in Love2d means that L5 is cross-platform as well. Surpisingly, with [love.js](https://github.com/Davidobot/love.js) you can even package many projects for the web. L5 is a framework built on top of Love2d so that you can write the Processing API you may already know or you're getting started learning and you don't need to learn Love2d at all.  So why not learn Love2d instead? I have. It's great. But if you want to quickly use intuitive Processing commands, and want to be able to rapidly build projects, and want to join a worldwide community of artists that share projects in the extended creative coding community, then L5 might be for you.

## Gotchas

* Lua is 1-indexed not 0-indexed
* 2D only (unless you implement your own 3d library or 2.5D)

## Install

Install Love2d for your system.

Clone or download L5. 

Create a new main.lua in the same directory as L5.lua. You should import the L5.lua file at the beginning of your main.lua file. Open main.lua in the IDE of your choice, then save and drag it onto the Love icon or launch it by running `love .` in your terminal from the same directory. 

## Reference

Coming soon

