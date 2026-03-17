Hi there! Welcome to L5 contributing! Here are a few things to know:

The GitHub issues are for bugs and feature requests for the L5 library itself. If you have a general question or bug programming with L5 please post it in the [L5 forum](https://discourse.processing.org/c/l5/)

Please be sure to review our [principles](https://github.com/L5lua/L5/blob/main/docs/PRINCIPLES.md). These things are very important to us.

Check out the [contributor docs](https://l5lua.org/contributing/) for more in-depth details about contributing code, bug fixes, and documentation.

## Contributor Guidelines

The following are some key points to keep in mind when contributing to L5:

### Get Assigned Before Working on an Issue
You should not “jump the queue” by filing a PR for an issue that either someone else has indicated willingness to submit a contribution or has already been assigned to someone else. We will always prioritize the “first assigned, first serve” order for accepting code contributions for an issue. If you file a PR for an issue while someone else is still working on the same issue, your PR will likely be closed.

### You may follow up on Stalled Issues
If you see that it has been a few weeks since the last activity on an issue with an assigned individual, you can leave a polite comment on the issue asking for progress and if they need help with the implementation. We generally allow for people to work on their contributions at their own pace, as we understand that most people will often be working on a volunteer basis, or it simply takes more time for them to work on the feature.

### Only Issues Approved for Implementation May Be Worked On
You should not file a pull request (or start working on code changes) without a corresponding issue or before an issue has been approved for implementation, that is because there is no guarantee that the proposal will be accepted. Any pull requests filed before a proposal has been approved will be closed until approval is given to the issue.

<!--### Include Unit Tests
Add any unit tests if you are working on adding new features or feature enhancement. Frequently run `npm test` and make sure all existing and new tests pass before submitting a PR.

### Follow Code Standards
Make sure your code follows the established code standards for L5. Any git commit and pull request must pass linting before it will be accepted. The easiest way for you to follow the right coding standard is to use the ESLint plugin available for your text editor with linting error highlighting (available for most popular text editors).-->

### Preparing Pull Requests
A pull request, more formally, is a request to a repo (in this case, the official L5 repo) to pull or merge changes from another repo (in this case, your forked L5 repo) into its commit history.

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

A little familiarity with Love2D goes a long way in understanding how L5 works. They have a great [wiki](www.love2d.org/wiki/Getting_Started) you can refer to for more details.
L5, overrides some of Love2D's default functions like `love.run()` and `love.draw()` to take control of the rendering loop and state to provide a Processing-style api.

Almost all internal state is stored inside a `L5_env` table that the library needs such as:

- current color mode
- whether looping is enabled
- pressed keys
- mouse movement flags
- current font info

L5 is does its drawing through a back buffer canvas which means:

- draw onto an offscreen image first
- then draw that image to the screen

This is a common graphics technique called [**double buffering**](https://en.wikipedia.org/wiki/Double_buffering).

This library is intentionally “global” and beginner-friendly. This is one of the most important things to understand when reading the codebase.

In many Lua codebases, you’ll see a style like:

- `local M = {}`
- `function M.foo() ... end`
- `return M`

Then users do:

- `local lib = require("lib")`
- `lib.foo()`

That is **not** the style here. L5 is more like Processing or p5 global mode:

- define globals
- provide simple function names
- let the user write very short sketches

Some of the key files and folders you will see in the L5 folder are as follows:

- `L5.lua` - The main library that contains all the code for L5
- `main.lua` - This is the main entry point / runnable sketch used by Love2D
- `examples` - This is where you can find example L5 projects
- `docs` - This is where the documentation lives

The other files and folders are either assets or other kinds of support files; in most cases, you shouldn't need to make any modifications.

How the code works is that, Love2D is essentially a game engine, it provides the window, input handling, and rendering engine. While `L5.lua` wraps that in a familiar Processing-style api.

### Running examples

1. Open one of the files in `L5/examples/`
2. Copy its contents
3. Paste it into the root `L5/main.lua`
4. Run the project with LÖVE using `love .`

## AI Usage Policy
This project does *not* accept fully AI-generated contributions. AI tools may be used assistively only. As a contributor, you should be able to understand and take responsibility for changes you make to the codebase.

We maintain the same stance on AI usage as p5.js. Please read the [AI Usage Policy](https://github.com/processing/p5.js/blob/main/AI_USAGE_POLICY.md) before proceeding.