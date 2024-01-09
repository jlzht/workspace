#!/usr/bin/env bash

# TODO:
# - add user feedback for what is happening in background
# - unify workspaces execute functions
# - try using vnc servers
# - create missing shared dirs (sharing a volume with a missing dirs, creates dir with root ownership)

check_env_var() {
    if [ -n "$WS_PROJECT_DIR" ]; then
      continue
    else
        echo "Error: WS_PROJECT_DIR is not set"
        exit 1
    fi
}

check_workspace() {
    case "$1" in
        "fmc"|"idf"|"ros"|"yoc") # make it dynamic
            continue
            ;;
        *)
          if ! [ -n "$1" ]; then
            echo "Error: invalid workspace selected: none"
            exit 1
          fi
            echo "Error: invalid workspace selected: $1"
            exit 1
            ;;
    esac
}

check_command() {
    case "$1" in 
      "build"|"init"|"run"|"stop"|"clear")
        continue
        ;;
      *)
        echo "Error: invalid command: $1"
        exit 1
        ;;
    esac
}

check_project ()
{
  # TODO: add checking to see if project matches with workspace using common files in workspaces (.gradlew, Kconfig, *.launch).
  if [ "$1" == "init" ]; then
    if [ -z "$2" ]; then
          echo "Error: no project selected"
          exit 1
    else
      if [ -d "$WS_PROJECT_DIR" ]; then
        if [ -d "$WS_PROJECT_DIR/$2" ]; then
          continue
        else
            echo "Error: $2 is not a valid directory or does not exist"
            exit 1
        fi
      else
        echo "Error: Directory $WS_PROJECT_DIR does not exist"
        exit 1
      fi
    fi
  fi
}

idf ()
{
    case "$1" in
     "build")
       docker build -t idf "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/espidf"
       folder="$WS_PROJECT_DIR/.shared/idf"
       if [ ! -d "$folder" ]; then
         mkdir -p $folder
       fi
       ;;
     "init")
        docker run -d --name idf -it \
          -v "$WS_PROJECT_DIR/.shared/idf/.espressif:/home/dev/.espressif/" \
          -v "$WS_PROJECT_DIR/.shared/idf/esp-idf:/home/dev/esp-idf/" \
          -v "/dev:/dev" --device-cgroup-rule='c 188:* rmw' \ # used for acessing USB devices
          -v "$WS_PROJECT_DIR/$2:/home/dev/$2" \
          --user=$(id -u):$(id -g) idf
       ;;
     "run")
       if docker ps -q --filter "name=idf" | grep -q .; then
         command=""
         if [ -n "$3" ]; then
           for ((i=3; i<=$#; i++)); do
               command="${command}${!i} "
           done
           echo "${command}"
           docker exec -it -w /home/dev/$2 idf sh -c "${command}"
         else
             echo "Error: command is empty."
         fi
       else
         echo "Error: fmc workspace is not running"
         exit 1
       fi
       ;;
     "stop")
       docker stop idf && docker rm idf
       ;;
     "clear")
       docker rmi idf
       ;;
  esac
}

yoc ()
{
   case "$1" in 
     "build")
       docker build -t yocto "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/yocto"
       folder="$WS_PROJECT_DIR/.shared/yocto"
       if [ ! -d "$folder" ]; then
         mkdir -p $folder
       fi
       ;;
     "init")
        docker run -d --name yocto -it  \
          -v "$WS_PROJECT_DIR/.shared/yocto/poky:/home/dev/poky" \
          -v "$WS_PROJECT_DIR/$2:/home/dev/poky/$2" \
          --user=$(id -u):$(id -g) yocto
       ;;
     "run")
       if docker ps -q --filter "name=yocto" | grep -q .; then
         command=""
         if [ -n "$3" ]; then
           for ((i=3; i<=$#; i++)); do
               command="${command}${!i} "
           done
           echo "${command}"
           docker exec -it -w /home/dev/poky/$2 yocto sh -c "${command}"
         else
             echo "Error: command is empty."
         fi
       else
         echo "Error: fmc workspace is not running"
         exit 1
       fi
       ;;
     "stop")
       docker stop yocto && docker rm yocto
       ;;
     "clear")
       docker rmi yocto
       ;;
  esac 
}

fmc () {
   case "$1" in 
     "build")
       docker build -t fabricmc "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/fabricmc" # find script location and build container
       folder="$WS_PROJECT_DIR/.shared/fabricmc"
       if [ ! -d "$folder" ]; then
         mkdir -p $folder
       fi
       ;;
     "init")
        docker run -d --name fabricmc -it -v "$WS_PROJECT_DIR/$2:/home/dev/$2" \
          -v "$WS_PROJECT_DIR/.shared/fabricmc/.gradle:/home/dev/.gradle" \
          -e DISPLAY=$DISPLAY \
          -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
          -e XDG_RUNTIME_DIR=/tmp \
          -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
          -v /dev/dri/card0:/dev/dri/card0 \
          -v /dev/dri/renderD128:/dev/dri/renderD128 \
          --user=$(id -u):$(id -g) \
          -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY fabricmc 
       ;;
     "run")
       if docker ps -q --filter "name=fabricmc" | grep -q .; then
         command=""
         if [ -n "$3" ]; then
           for ((i=3; i<=$#; i++)); do
               command="${command}${!i} "
           done
           echo "${command}"
           docker exec -it -w /home/dev/$2 fabricmc sh -c "${command}"
         else
             echo "Error: command is empty."
         fi
       else
         echo "Error: fmc workspace is not running"
         exit 1
       fi
       ;;
     "stop")
       docker stop fabricmc && docker rm fabricmc
       ;;
     "clear")
       docker rmi fabricmc
       ;;
    esac
}

ros () {
   case "$1" in
     "build")
       docker build -t ros "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/ros"
       folder="$WS_PROJECT_DIR/.shared/ros"
       if [ ! -d "$folder" ]; then
         mkdir -p $folder
       fi
       ;;
     "init")
        docker run -d --name ros -it -v "$WS_PROJECT_DIR/$2:/home/dev/$2" \
          -e DISPLAY=$DISPLAY \
          -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
          -e XDG_RUNTIME_DIR=/tmp \
          -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
          -v /dev/dri/card0:/dev/dri/card0 \
          -v /dev/dri/renderD128:/dev/dri/renderD128 \
          --user=$(id -u):$(id -g) \
          -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY ros
       ;;
     "run")
       if docker ps -q --filter "name=ros" | grep -q .; then
         command=""
         if [ -n "$3" ]; then
           for ((i=3; i<=$#; i++)); do
               command="${command}${!i} "
           done
           echo "${command}"
           docker exec -it -w /home/dev/$2 ros sh -c "${command}"
         else
             echo "Error: command is empty."
         fi
       else
         echo "Error: ros workspace is not running"
         exit 1
       fi
       ;;
     "stop")
       docker stop ros && docker rm ros
       ;;
     "clear")
       docker rmi ros
       ;;
    esac
}

ws_execute () {
  case "$1" in 
      "idf")
        idf "${@:2}"
        ;;
      "yoc")
        yoc "${@:2}"
        ;;
      "ros")
        ros "${@:2}"
        ;;
      "fmc")
        fmc "${@:2}"
        ;;
      *)
        echo "Error: invalid workspace: $1"
        exit 1
        ;;
  esac
}

check_workspace $1
check_command $2
check_project $2 $3


ws_execute "$@" 

#IDEAS:
# - add run commands and workspaces using json [using jq]
