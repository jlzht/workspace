#!/usr/bin/env bash

log() {
  echo "$1" >&2
}

# This is a simple yaml element extractor
extract() {
  # Checks arguments
  if ! [ -n "$1" ] || ! [ -n "$2" ]; then
    echo ""
    return
  fi
  # Removes comments
  local file=$(echo "$1" | sed 's/ #.*//' | sed '/^$/d')
  # Tries to extract $2 element
  local node=$(echo "$file" | sed -n "/^$2:/,/^[A-Za-z].*:/{/^\s/{s/\s\s//;p;}}")
  if [ "$node" == "" ]; then
    node=$(echo "$file" | sed -n "/^$2:/,/^[A-Za-z].*:/{/\s/{s/\s\s//;p;}}")
  fi

  local num=$(echo "$node" | grep -o '^[A-Za-z].*:' | wc -l )
  if [ "$num" -eq "1" ]; then
    # add case for array in one line
    if [[ "${node}" == $2:* ]]; then
      echo "$node" | cut -d : -f 2 | tr -d '"'
      return
    fi
    echo "$node"
    return
  fi
  if [ "$num" -eq "0" ]; then
    echo "$node" | sed "s/\-//" | tr -d '"'
    return
  fi
  local frag=$(echo "$node" | sed -n "/^$2/p" | cut -d : -f 2 | tr -d '"')
  if ! [ "$frag" == "" ]; then
    echo $frag
    return
  fi
  echo "$node"
}

# Get ws configuration file
check_config() {
  if ! [ -n "$HOME/.config/workspace/config.yml" ]; then
    echo "Error: no configuration file found"
    exit 1
  else
    echo "`cat $HOME/.config/workspace/config.yml`"
  fi
}

ws() {
  local file=$(check_config)
  file=$(extract "$file" "$1")
  if ! [ -n "$file" ]; then
    echo "Error: $1 workspace does not exist in configuration file"
    exit 1
  fi
  if [ "$2" != "stop" ]; then
    file=$(extract "$file" "$2")
    if ! [ -n "$file" ]; then
      echo "Error: no valid ws action provided"
      exit 1
    fi
  fi

  case "$2" in
    "build")
      local path=$(extract "$file" path)
      local args=$(extract "$file" args | sed 's/ /\-\-build-arg /')
      local build="docker build $args -t $1 $path"
      echo $build
      exit 0
    ;;
    "run")
      local env=$(extract "$file" env | sed 's/ /\-e /')
      local volumes=$(extract "$file" volumes | sed 's/ /\-v /')
      local run="docker run -d --name $1 -it $volumes $env $1"
      echo $run
      exit 0
      ;;
    "exec")
      if docker ps -q --filter "name=$1" | grep -q .; then
        local args=$(extract "$file" args)
        local cmd=$(extract "$file" cmd)
        local run=$(extract "$cmd" "$3")
        if ! [ -n "$run" ]; then
          echo "Error: no command provided or missing"
          exit 1
        fi
        local exec="docker exec -it $args $1 sh -c '${run}'"
        echo $exec
        exit 0
      else
        echo "Error: $1 doesn't seem to be running"
        exit 1
      fi
    ;;
    "stop")
      echo "Info: stopping $1 workspace!"
      if ! docker ps -q --filter "name=$1" | grep -q .; then
        echo "Error: $1 doesn't seem to be running"
        exit 0
      else
        docker stop $1 > /dev/null  && docker rm $1 > /dev/null
        exit 1
      fi
    ;;
    *)
      if ! [ -n "$2" ]; then
        echo "Error: no action provided"
        exit 1
      fi
      echo "Error: $2 action not found in configuration file"
      exit 1
    ;;
  esac
  exit 0
}

ws "$@"
