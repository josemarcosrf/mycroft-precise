#!/usr/bin/env bash

say() {
 echo "$@" | sed \
         -e "s/\(\(@\(red\|green\|yellow\|blue\|magenta\|cyan\|white\|reset\|b\|u\)\)\+\)[[]\{2\}\(.*\)[]]\{2\}/\1\4@reset/g" \
         -e "s/@red/$(tput setaf 1)/g" \
         -e "s/@green/$(tput setaf 2)/g" \
         -e "s/@yellow/$(tput setaf 3)/g" \
         -e "s/@blue/$(tput setaf 4)/g" \
         -e "s/@magenta/$(tput setaf 5)/g" \
         -e "s/@cyan/$(tput setaf 6)/g" \
         -e "s/@white/$(tput setaf 7)/g" \
         -e "s/@reset/$(tput sgr0)/g" \
         -e "s/@b/$(tput bold)/g" \
         -e "s/@u/$(tput sgr 0 1)/g"
}

# if [ -z "$PYPI_USR" ]
#   then
#     say @red[["Please set the env. variable PYPI_USR before running this script"]]
#     say @red[["PYPI_USR should be set to the private pypi server username"]]
#     exit 1;
# fi

# if [ -z "$PYPI_PWD" ]
#   then
#     say @red[["Please set the env. variable PYPI_PWD before running this script"]]
#     say @red[["PYPI_USR should be set to the private pypi server password"]]
#     exit 1;
# fi

# check current directory
current_dir=${PWD##*/}
if [ "$current_dir" == "scripts" ]; then
    say @red[["This scripts should be executed from the root folder as: ./scripts/build_docker.sh"]]
    exit
fi


VERSION=$(python -c 'from precise import __version__; print(__version__)')

say @blue[["Using version $VERSION"]]

{
    docker build --rm \
        -t jmrf/precise:$VERSION \
        -t jmrf/precise:latest \
        -f Dockerfile .

} || {
  say @red[["Couldn't build Docker mycraft/precise image... exiting"]];
  exit 1;
}
