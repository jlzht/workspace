### Workspace
This is a simple Bash script designed to manage Docker containers for isolated development
environments. It simplifies the process of running development tools and services inside Docker containers.
It is particularly useful when libraries or tools are required but not available through the host's
package manager, or dealing with environments where installing gazillions of dependencies in host
is cumbersome.

### Installation

Make sure you have Docker and Bash installed on your system. Then, place the script
in a directory included in your `$PATH`, or call it directly from where you have the script saved.
Dont forget to add permissions

### Example

Create a configuration YAML file at `$HOME/.config/workspace/config.yml` This file defines the
settings for each workspace you want to manage.

```
<workspace name>:
  build:
    path: "<path/to/dockerfile>"
    args:
      - "UID=$(id -u)"
      - "GID=$(id -g)"
  run:
    args:
      - "--user=$(id -u):$(id -g)" # enables wayland display to be used
    volumes:
      - <path/to/volumes>
    env:
      - "XDG_RUNTIME_DIR=/tmp"
      - "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
  exec:
    args: '-w </path/to/startup>'
    cmd:
      shell: "bash" # accesses the container
      action1: "<command A>" # run something
      action2: "<command B>"
```
To open a terminal session inside the container:
```
$ ws <workspace name> exec tty shell
```
To run a predefined action (e.g., a command inside the container):
```
$ ws <workspace name> exec action1
```

### Workflow Example
By sharing a project path as a volume, a compiler, linter, and formatter can be installed in
the container and invoked using `ws exec <project> <action>`. To be used by host in its
environment.

```
    HOST
            NEOVIM EDITOR ─────────────────────────────> FILE
                  Λ                                       Λ
                  ⎪                                       ⎪
             (uses stdout)                       (Shared by volume)
                  ⎪                                       ⎪
                  ⎪                                       ⎪
    CONTAINER     ⎪                                       ⎪
                  ⎪                                       ⎪
                  V                                       ⎪
              Linter/Formatter                         Compiler
              LSP Server
```
