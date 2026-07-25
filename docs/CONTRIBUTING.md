# Contributing

Welcome to L5 contributing. 

**This is the place to learn about contributing to the L5 library codebase itself**. There is a broader overview on [contributing on L5's website](https://l5lua.org/contributing/). If you're looking to contribute to the website (for example, with the reference, fixing typos, or adding in a tutorial), its code lives in a separate repository at [L5lua/L5-website](https://github.com/L5lua/L5-website). This repository is strictly for the core library.

The GitHub issues are for bugs and feature requests for the L5 library itself. If you have a general question or need help writing your own programs with L5 please post in the [L5 forum](https://discourse.processing.org/c/l5/).

Please be sure to review our principles (TODO: Add principles!)

## Contributor Guidelines for the L5 library

This section is adapted from the [p5.js contributor guidlines](https://github.com/processing/p5.js/blob/main/contributor_docs/contributor_guidelines.md).

*Issues* are usually bug reports or feature requests. A *pull request* is often the result of working to address an issue. It's an official request to the official L5 codebase to pull or merge changes from another repo (in this case, your forked L5 repo where you worked on fixing a bug listed in an issue, for example).

### Please create an issue prior to a pull request

You should file an [issue](https://github.com/l5lua/l5/issues) prior to a pull request. This will allow us to discuss possible implementation details and give feedback.

### Get Assigned Before Working on an Issue

You should not "jump the queue" by filing a pull request for an issue that someone else has recently indicated willingness to submit a contribution to or has already been assigned to someone else. We will prioritize the "first assigned, first serve" order for accepting code contributions for an issue. 

### But you may follow up on Stalled Issues

If you see that it has been a few weeks since the last activity on an issue with an assigned individual, you can leave a polite comment on the issue asking for progress and if they need help with the implementation. We generally allow for people to work on their contributions at their own pace, as we understand that most people will often be working on a volunteer basis, or it simply takes more time for them to work on the feature.

## Quickstart

If you want to work/contribute to L5 codebase as a developer, you can follow the following steps:

1. [Create a fork of L5.](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
2. [Clone your created fork to your computer.](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
3. [Add upstream using the following command](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/configuring-a-remote-repository-for-a-fork):

  ```
  git remote add upstream https://github.com/L5lua/L5
  ```

4. Make sure your machine has [Love2D](https://love2d.org/#download) installed; check it with the following command:

  ```
  love --version
  ```

5. Test everything is working with:

  ```
  love .
  ```

6. Create a git branch of the `main` branch having a descriptive branch name using:

  ```
  git checkout -b [branch_name]
  ```

7. As you start making changes to the codebase, it is preferred that you aim to [commit](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/about-commits) early and often rather than lump multiple big changes into one commit. A good guideline is to commit whenever you have completed a subtask that can be described in a sentence.

- Stage all changes for committing into git with the following command.

```
git add .
```

- To commit the changes into git, run the following command.

```
git commit -m "[your_commit_message]"
```

8. Once done, you can push the changes and create a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).

## Codebase overview

L5 is built with the Love2d framework underlying its codebase. A little familiarity with Love2D goes a long way in understanding how L5 works. They have a great [wiki](www.love2d.org/wiki/Getting_Started) you can refer to for more details. L5 overrides some of Love2D's default functions like `love.run()` and `love.draw()` to take control of the rendering loop and state to provide a Processing/p5-style API and approach. This allows us to do things like allow drawing graphics inside events such as mousePressed(), keyPressed() or even setup() - which would not normally be possible in Love2d.

Almost all internal state is stored inside a `L5_env` table that the library needs such as:

* current color mode
* whether looping is enabled
* pressed keys
* mouse movement flags
* current font info

L5 does its drawing through a back buffer canvas which means:

* draw onto an offscreen image first
* then draw that image to the screen

This is a common graphics technique called [**double buffering**](https://en.wikipedia.org/wiki/Double_buffering).

This library is intentionally "global" and beginner-friendly. This is one of the most important things to understand when reading the codebase.

In many Lua codebases, you’ll see a style like:

```
local M = {}
function M.foo() ... end
return M
```

Then users do:

```
local lib = require("lib")
lib.foo()
```

That is **not** the style here. L5 applies a Processing/p5 approach with defined global variables accessible to the user, simplified function calling, supporting the ability to do *code sketching* with fewer lines of code.

Some key files and folders in a L5 folder:

* `L5.lua` - The main library that contains all the code for L5
* `main.lua` - This is your code sketch file, instead of (for example) p5.js's sketch.js
* `examples` - This is where you can find example L5 projects
* `docs` - This is where the documentation lives

The other files and folders are either assets or other kinds of support files; in most cases, you shouldn't need to make any modifications.

### Running examples

1. Open one of the files in `L5/examples/`
2. Copy its contents
3. Paste it into the root `L5/main.lua`
4. Run the project with LÖVE from within the root folder with `love .`

## AI Usage Policy

As permacomputing principles underlie the goals of this coding library, please don't include Large Language Models (LLMs) in code contributions.

We maintain the same stance on AI usage as p5.js. AI tools may be used assistively only. Please read the [AI Usage policy](https://github.com/processing/p5.js/blob/main/AI_USAGE_POLICY.md#what-ai-tools-can-do) before proceeding.
