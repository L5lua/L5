# Welcome to L5

![L5 logo](assets/L5-logo-blob.png)

L5 is a fun, fast, cross-platform, and lightweight implementation of the Processing API in Lua. It is a free and open source coding library to make interactive artwork on the computer, aimed at artists, students, and anyone that wants a flexible way to prototype art, games, toys, and other software experiments in code.

## Overview

L5 brings the familiar Processing creative coding environment to Lua, offering some of the best aspects of both Processing and p5.js with some twists of its own. But you don't need to know Processing already to get started with L5. L5 is built on top of the Love2D framework, and offers near-instant loading times and excellent performance while maintaining the intuitive API that makes [Processing](https://processing.org/) accessible to artists and designers. *L5 is not an official implementation of Processing or the Processing Foundation. It is a community-created project.*

> Processing is not a single programming language, but an arts-centric system for learning, teaching, and making visual form with code. *-[Processing.py reference](https://py.processing.org/reference/)*


## Key Features

- **Lightning fast**: Scripts, images, and audio load near-instantly
- **Minimal footprint**: L5 (~6MB, from Love2D ~4.5MB + LuaJIT ~1.5MB) vs Processing (~500MB) vs p5.js (~1-4MB + browser ~250-355MB)
- **Cross-platform**: Runs on Windows, macOS, Linux, and even Raspberry Pi
- **Synchronous execution**: Code runs in predictable order, no async complexity
- **Desktop-focused**: Optimized for installations and standalone applications

## How L5 Compares

### vs Processing
- **Similar**: Synchronous execution, desktop-focused, compiled with error checking
- **Different**: Dynamic typing (no need to declare variable types), smaller footprint

### vs p5.js
- **Similar**: Dynamic typing, helper functions (hex colors, HTML color names, `describe()`)
- **Different**: Synchronous (no callbacks), desktop-native, much faster loading

## Why Choose L5?

**Lua Advantages**
- Simple, consistent syntax that rarely changes
- Excellent performance, especially with LuaJIT
- Stable and works well on old hardware
- Perfect for long-running installations
- Easy integration with host operating system

**Love2D Foundation**
- Mature, well-tested 2D game framework
- Cross-platform compatibility out of the box
- Optional web deployment via love.js
- Active community and ongoing development

**Processing API Familiarity**
- No need to learn Love2D directly
- Leverage existing Processing knowledge and tutorials
- Join the worldwide creative coding community
- Rapid prototyping and project development

## Important Notes

- **1-indexed**: Lua arrays start at 1, not 0 (use `#` to get array/string length)
- **2D only**: Currently limited to 2D graphics (3D libraries possible but not built-in)
- **Tables everywhere**: Lua uses tables for arrays, objects, and data structures
- **OOP patterns**: Check Lua documentation for object-oriented programming approaches

## Getting Started

1. **Install Love2D** from [love2d.org](https://www.love2d.org/)
2. **Download L5** (clone the repository or download the L5.lua file to your project directory)
3. **Create or edit main.lua** in the same directory as L5.lua
4. **Require L5** at the top of your main.lua file with `require ("L5")`
5. **Write** your program code in main.lua
6. **Run** your program by dragging main.lua onto Love2D icon or running `love .` in terminal

### Basic Example

```lua
--main.lua
require("L5")

function setup()
    size(400, 400)
    windowTitle("My L5 Sketch")
end

function draw()
    background(220)
    
    -- Draw a circle that follows the mouse
    fill(100, 150, 200)
    circle(mouseX, mouseY, 50)
    
    -- Draw some text
    fill(0)
    text("Hello L5!", 20, 30)
end
```

## Community and Support

While L5 is a new project with growing documentation, it benefits from:
- The welcoming Processing community and their decade+ of resources
- Extensive Processing tutorials, books, and forums that translate well to L5
- The stable Lua and Love2D ecosystems
- Active development and community contributions

*Note: As L5 is nascent, documentation and examples are still growing compared to the mature Processing ecosystem.*

## Contributing

We welcome contributions! Before submitting pull requests, please open an issue to discuss proposed changes.

### Ways to Help
- **Spread the word** through social media and community
- **Create documentation** and tutorials
- **Build example programs** showcasing L5 capabilities
- **Teach workshops** using L5
- **Test on different systems** and report compatibility
- **File bug reports** with detailed reproduction steps
- **Fix code issues** and improve functionality
- **Create educational content** like zines or video tutorials
- **Develop add-on libraries** or document Lua ecosystem integration

## Reference Documentation

Coming soon - comprehensive API reference and examples.

---

*L5 aims to make creative coding accessible, fast, and fun while leveraging the power and simplicity of Lua.*
