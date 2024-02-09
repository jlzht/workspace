#!/usr/bin/env bash

# There is no YAML parser, just a bunch of seds

get_nodes () {
  if ! [ -n "$1" ] || ! [ -n "$2" ]; then
    echo ""
    return
  fi
  local node=$(echo "$1" | sed -n "/$2:/,/^[A-Za-z].*:/{/\s/{s/\s\s//;p;}}")
  if [ "$1" == "$node" ]; then
    echo "$node" | sed -n "/$2/p" | cut -d : -f 2 | tr -d '"'
    exit 0
  fi
  local num=$(echo "$node" | grep -o '^[A-Za-z].*:' | wc -l )
  if [ "$num" -eq "1" ]; then
    if [ "$2" == *"$1"*  ]; then
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
  echo "$node"
}

check_config() {
  if ! [ -n "$HOME/.config/workspace/config.yml" ]; then
    echo "Error: no configuration file found"
    exit 1
  else
    echo "`cat $HOME/.config/workspace/config.yml`"
  fi   
}

ws_exec () {
  local file=$(check_config)
  file=$(get_nodes "$file" "$1")
  if ! [ -n "$file" ]; then
    echo "Error: $1 workspace does not exist in configuration file"
    exit 1
  fi
  if [ "$2" != "stop" ]; then
    file=$(get_nodes "$file" "$2")
    if ! [ -n "$file" ]; then
      echo "Error: no valid ws action provided"
      exit 1
    fi
  fi

  case "$2" in 
    "build")
      local path=$(get_nodes "$file" path)
      local env=$(get_nodes "$file" env | sed 's/ /\-\-build-arg /')
      build="docker build $env -t $1 $path"
      eval $build
      exit 0
    ;;
    "run")
      local args=$(get_nodes "$file" args)
      local volumes=$(get_nodes "$file" volumes | sed 's/ /\-v /')
      init="docker run -d --name $1 -it $volumes $args $1"
      eval $init
      exit 0
      ;;
    "exec")
      if docker ps -q --filter "name=$1" | grep -q .; then
        local args=$(get_nodes "$file" args)
        local cmd=$(get_nodes "$file" cmd)
        cmd=$(get_nodes "$cmd" $3)
        if ! [ -n "$cmd" ]; then
          echo "Error: no command provided or missing"
          exit 1
        fi
        run="docker exec -it $args $1 sh -c '${cmd}'"
        eval $run
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

ws_exec "$@" 
