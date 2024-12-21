### Workspace
workspace is a simple Bash script designed to manage Docker containers for isolated development
environments. It simplifies the process of running development tools and services inside containers.
This is particularly useful when libraries or tools are required but not available through the host's
package manager, in environments where installing gazillions of dependencies is cumbersome, or when dealing
with "works on my machine" issues.

### Installation

Make sure you have Docker and Bash installed on your system. Then, place the workspace script
in a directory included in your $PATH, or call it directly from where you have the script saved.
Dont forget to add permissions

### Example

Create a configuration YAML file at $HOME/.config/workspace/config.yml. This file defines the
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
the container and invoked using ws exec <project> <action>, to be used by host, in host
environment.
```
    HOST
            NEOVIM EDITOR ─────────────────────────────> FILE
                  Λ                                       Λ
                  ⎪                                       ⎪
              (invokes)                           (Shared by volume)
                  ⎪                                       ⎪
                  ⎪                                       ⎪
    CONTAINER     ⎪                                       ⎪
                  ⎪                                       ⎪
                  V                                       ⎪
              Linter/Formatter                         Compiler
              LSP Server
```
