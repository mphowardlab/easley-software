# Easley software

This repository contains scripts for building and installing software
on the [Easley](https://hpc.auburn.edu/hpc/docs/hpcdocs/build/html/easley/easley.html)
cluster at Auburn University. The goal is to keep a shared set of software to:

1. Make it easier to get started (no need to compile yourself!),
2. Keep versioned software so that environments can be reproduced.
3. Conserve disk space!

This repository serves as a public record of how the software was built that can be
rolled back as dependencies on Easley change. You typically **do not** need to download
this code yourself.

## New users

If you are new to the group, you need to configure your shell to make this software
available to you. Run the following command **one** time:

```bash
bash /home/shared/mph0043_lab/software/config_bash.sh
```

This script modifies your `.bashrc` file in the following ways:

1. Define the environment variables `$SCRATCH` and `$GROUP`. `$SCRATCH` points
   to a directory `/scratch/<username>` that you should use for I/O intensive jobs.
   `$GROUP` is a shortcut to get to the shared directory where this software is
   installed.
2. Add the modulefiles for the group software so that it is available to you to load
   by `module` commands.
3. Load the `git` module by default (good practice for working with code!).
4. Copy a standard `.vimrc` file to configure your text editor.

A backup copy of your current `.bashrc` is stored as `.bashrc.bak` if you wish to
revert the changes. Your `.vimrc` will be overwritten.

After running this command, you need to log out and in to have the changes take effect.

## Current users

After you have set up your shell, use standard `module` commands to load and use the
installed software. For example, to load the 2021Apr python virtual environment, which
includes scientific python and simulation software, use:

```bash
module load python/2021Apr
```

Pretty easy!

## Software maintainers

You are required to rename this repository `software` when you download it:

```git
git clone https://github.com/mphowardlab/easley-software.git software
```

Failure to do so will cause all scripts to fail. (Why not just name this `software` then?
This choice was initially made so that it is easier to identify the repository. Eventually,
this may change but for now it stays.)

The scripts to build new software are in the `build` directory. There is one directory
for each software module that can be installed. To build the software, execute its
`build.sh` file after updating the appropriate `version`. The build script is
a self-contained procedure that pulls the required source code, compiles and installs
the software, and also sets the new `modulefile` from the supplied template.

Currently, software is installed into the repository in `install` and the module files
are also placed into the repository in `modulefiles`. These directories are intentionally
ignored by git.
