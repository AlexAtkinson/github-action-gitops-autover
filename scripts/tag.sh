#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# tag.sh
#
# Description
#     Tags repo with version.
#
# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------

show_help() {
echo -e "$(cat << EOF

NAME
    tag.sh

SYNOPSIS
    ${0##*/} [OPTION]

DESCRIPTION
    Adds version tag to repo.

OPTIONS
    -d \e[4mDEBUG\e[0m
        Indicates build was in DEBUG mode, and appends '.debug' to the version.
    -h \e[4mHELP\e[0m
        Show this help menu.

EXAMPLES:
    Execute postbuild steps for a DEBUG build:
      ./tag.sh -d

EOF
)"
exit 1
}

# ------------------------------------------------------------------------------
# Arguments
# ------------------------------------------------------------------------------

OPTIND=1
while getopts "hs:d" opt; do
  case $opt in
    h)
      show_help
      ;;
    d)
      arg_d='set'
      ;;
    *)
      echo "ERROR: Invalid argument.!"
      show_help
      ;;
  esac
done
shift "$((OPTIND-1))"

relative_path="$(dirname "${BASH_SOURCE[0]}")"
dir="$(realpath "${relative_path}")"

# ------------------------------------------------------------------------------
# Main Operations
# ------------------------------------------------------------------------------

if [[ -n $arg_d ]]; then
  newVersion="$(/usr/bin/env bash -c "${dir}/detectNewVersion.sh").debug"
else
  newVersion=$(/usr/bin/env bash -c "${dir}/detectNewVersion.sh")
fi

git tag "${newVersion}"
git push --tags
