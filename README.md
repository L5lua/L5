# L5

An implementation of a Processing-like API in Lua.

Built on the Love2d framework.

## Why?

Lua is fun. It's a dynamic scripting language like Javascript. The language is tiny in terms of bandwidth and in functions. It is easy to learn, works on old hardware, and stable. The syntax is consistently simple, and unlike Javascript, rarely changes over its long history. It is incredibly fast and works really well on desktop from powerful machines to Raspberry Pi. It is perfect for building an interactive installation and letting it run for months, or for a program that you need to integrate with your host OS, or for making games or interactive artworks on the computer. It can be really fun to write in it.

Lua itself is a language with mechanisms but unlike Python, few *batteries*. It isn't "everything and the kitchen sink". Unlike Javascript in the browser, it lacks a built-in canvas element. That's where Love2d comes in.

Love2d (stylized LÖVE) is a framework to build 2d games in Lua. It is free and open-source and works on Mac, Windows, PC, Android and iOS. Building L5 in Love2d means that L5 is cross-platform as well. Surpisingly, with [love.js](https://github.com/Davidobot/love.js) you can even package many projects for the web. L5 is a framework built on top of Love2d so that you can write the Processing API you may already know or you're getting started learning and you don't need to learn Love2d at all.  So why not learn Love2d instead? I have. It's great. But if you want to quickly use intuitive Processing commands, and want to be able to rapidly build projects, and want to join a worldwide community of artists that share projects in the extended creative coding community, then L5 might be for you.

## Compared to Processing and p5.js

L5 blends the Processing and p5.js paradigms, offering some advantages with this combination. But choice of language is a personal thing! Here is a summary:

L5's syntax is somewhat more similar to p5.js. For example, it is a dynamically typed language. You do not need to declare strings, objects, integers, floats, etc.

But where p5.js is asyncronous and requires methods to deal with this, L5 is simply syncronous, which is more like Processing. Lines of code are guaranteed to run in order and we only need a setup() and draw(). In fact draw() is optional and you can use event functions like mousePressed() or keyTyped().

L5 has adopted some of the helper functions that p5.js added on top of the Processing API. For example, you can use hexcodes and html color names. There is a describe() function for screen readers in the command line. We use mouseIsPressed rather than mousePressed.

Like Processing, L5 gets compiled, so if you have a syntax or other error, your program won't compile and will give an error message. In p5.js, it has a built-in friendly error system, and your script.js will continue to run even if you make an error.

Like Processing, L5 is focused on desktop, not web. Though there are libraries such as [love.js](https://github.com/Davidobot/love.js) that do allow for web use.

L5 is extremely fast and minimal. Scripts, images and audio load near-instantly, which makes it a good candidate to run on recent as well as ancient or low-spec hardware. The Love2d library that L5 is built on is about 4.5MB with LuaJIT 1.5MB. In contrast, Processing on my system is about 500MB. p5.js is about 1MB minified or 4MB unminified, though it also requires a browser (Firefox is 250MB and Chromium is 355MB on my system).

Like Processing-java (a tool to run Processing on the command line), L5 can be scripted from the command line and it does run on a server. p5.js is not intended to run on a server. 

In terms of community and support, I've found the Processing community to be one of the most welcoming and positive code-based communities online, and there is over a decade of documentation, example code, video tutorials and books to help learners, along with thriving forums. The Processing Foundation are caretakers of the languages and this vibrant community. As L5 is a nascent project, there is more limited documentation, examples and support.

## Gotchas

* Lua is 1-indexed, not 0-indexed. There are some nice advantages to this, particularly in loops. Lengths of arrays, strings, etc can be found by affixing # before its name.
* 2D only, at least for now (unless you implement a 3d library or your own 2.5D)
* Lua features the table to build data structures. Arrays and objects are built out of them. For OOP, you should look up the paradigms for how to do so in Lua, or check out the example code.

## Install

[Install Love2d](https://www.love2d.org/) for your system.

Clone or download L5. 

Create a new main.lua in the same directory as L5.lua. You should import the L5.lua file at the beginning of your main.lua file. Open main.lua in the IDE of your choice, then save and drag it onto the Love icon or launch it by running `love .` in your terminal from the same directory. 

## Reference

Coming soon

## Contributing

This is a nascent project. Contributions are welcomed. You can send an [email](https://leetusman.com/info/) or open up an issue. Opening an issue and proposing changes are preferred prior to submitting pull requests.

### Ways to help out

* Get the word out about L5 through social media or word-of-mouth
* Contribute documentation or create tutorials
* Create example programs
* Teach a workshop using L5
* Test L5 on various systems
* File a bug report
* Fix something in the code
* Make a zine about L5
* Contribute an add-on library or document how to integrate with the wider Lua ecosystem
