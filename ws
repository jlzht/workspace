#!/usr/bin/env bash

# TODO: add user feedback for what is happening in background

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
          if [ -n "$1" ]; then
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
  continue
}

yoc ()
{
  continue
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
           echo $#
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
  continue
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
# - 
