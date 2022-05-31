# Easley

## Initial setup and connection

1. Request a [user account](https://hpc.auburn.edu/hpc/docs/hpcdocs/build/html/easley/access.html#request-an-account).
You should select Howard as your "sponsor". You will get an email confirmation
after you account is approved by me and the HPC admins.

2. [Connect to the VPN](https://libguides.auburn.edu/vpn) if you are off campus
or using WiFi (regardless of location). You will want to make sure that your
[Duo 2-factor authentication](https://duo.auburn.edu) (2FA) is setup to use push
notifications.

3. [Connect to Easley](https://hpc.auburn.edu/hpc/docs/hpcdocs/build/html/easley/access.html#connect-to-easley).

    If you are a Unix (Mac or Linux) user, open a terminal and connect with `ssh`:

    ```bash
    ssh <auburn-username>@easley.auburn.edu
    ```

    You will be prompted to enter your login credentials (including 2FA), then you
    will arrive at a splash screen in your home directory. To simplify the
    connection process in future, you can add Easley as a Host entry in your
    `~/.ssh/config` file:

    ```
    Host easley
        HostName easley.auburn.edu
        User <auburn-username>
    ```

    so that you can use the shorter command:

    ```bash
    ssh easley
    ```

    If you are a Windows user, download [PuTTY](https://www.putty.org). Enter
    `easley.auburn.edu` as the hostname, and connect to port 22 with ssh. You will
    be asked for your login credentials, then you will get a terminal similar to the
    Unix users.

4. In order to use the group software and handle some common configuration
tasks, run the following from your command prompt:

    ```bash
    ./home/shared/mph0043_lab/software/config_bash.sh
    ```

    This command should only be run **once** (the first time you login), and does
    not need to be repeated in future.

5. Log out using the `logout` command. The changes you have made will take
effect the next time you login.

## Software

Easley has a large set of software already installed for you, typically with
multiple versions. The software that is available may change depending on what
else you have already loaded (for example, the compiler you are using). The
packages are managed using the `module` tool. To see what software has already
been loaded, use:

```bash
module list
```

By default, a few things will already be loaded for you when you log in. To see
all the software that is available:

```bash
module avail
```

You can also check for specific versions of a particular package:

```bash
module avail python
```

To load a particular software and make it available for use:

```bash
module load python/3.9.2
```

If you run `python --version`, you should see `Python 3.9.2`.

To deactivate it:

```bash
module unload python/3.9.2
```

and running `python --version` will give you the system python (currently
`Python 2.7.5`).

If a package is marked with a `(D)`, it is the "default" that will be
loaded if you don't specify the full package name. If a version is marked with
an `(L)`, it is currently loaded. For convenience, you can tab complete names
of modules so that you don't have to type the full name manually.

Our group also has software installed for everyone to use. You should see it
at the top when you do `module list`, under the heading
`/home/shared/mph0043_lab/software/modulefiles`. You can activate this software
in the same way as any of the other modules.

If you get yourself in a mess with your modules, you can always log out and log
back in again to get a clean start!

## Using Anaconda Python

### Initial setup

1. Load a specific version of Anaconda. This example uses `3.8.6`:

    ```bash
    module load python/anaconda/3.8.6
    ```

2. To make sure the shared Anaconda installation can create environments
correctly, you need to create a `~/.condarc` file and add the following:

    ```
    pkgs_dirs:
     - ~/.conda/pkgs
     - /tools/anacondapython-3.8.6/pkgs
    ```

    The white space on lines 2 & 3 is important, so make sure you preserve it:
    `[space][-][space][rest of the line]`. In line 3, the version number should
    match the one you loaded. After creating this file, run the command `conda info`
    and you should see two entries in the "package cache" entry.

### Creating environments

You can now create new conda environments that get installed in `~/.conda/envs`:

```bash
conda create -n testenv
```

You can also create new environments at a specific location:

```bash
conda create -p /path/to/env
```

Note that there are many additional options for `conda create`. For example,
you can set the version of Python to use in the environment. Refer to the
Anaconda documentation for more details.

### Using environments

You can activate / deactivate these environments using `source activate`:

```bash
source activate testenv
```

or

```bash
source activate /path/to/env
```

You should now see the name of the environment preprended to your command prompt
like `(testenv)`.

You may get a suggestion to run `conda init` instead so that you can activate
the environment using `conda activate`. However, this command modifies your
`.bashrc` file, so I don't recommend it when `source activate` works just fine.

### Installing in an environment

After you activate an environment, you can use `conda` or `pip` to install new
software. This gives you a nice way to create isolated environments with
compatible versions of software. You should always prefer to install from
`conda` *before* `pip` when using Anaconda in order to get the best dependency
management.

Use `conda install` to install new packages. You may need to add a channel like
`conda-forge`:

```bash
conda install -c conda-forge hoomd
```

Note that when using `conda-forge`, it can take a long time to solve for an
environment. You may need to be patient in these cases, or reconsider what you
are installing into the the same environment.

To uninstall a package, use `conda remove`:

```bash
conda remove hoomd
```

### Deactivating and removing an environment

Regardless of how the environment was activated, you deactivate it the same way:

```bash
conda deactivate
```

To remove an environment created by name (`-n`), first deactivate it then use:

```bash
conda remove -n testenv --all
```

To remove an environment created by prefix, first deactivate it then delete it:

```bash
rm -r /path/to/env
```
