#!/usr/bin/env bash
# --------------------------------------------------------------------------------------------------
# detectPreviousVersion.sh
#
# Description
#     Detect previous version.
#
# --------------------------------------------------------------------------------------------------
# Help
# --------------------------------------------------------------------------------------------------

help="\

NAME
      detectPreviousVersion.sh

SYNOPSIS
      ${0##*/} [-hvc]

DESCRIPTION
      Detects most recent version tag of the repository.
      Prints only the detected version to stdout by default.
      Assumes version '0.0.0' if no previous versions are detected.

      The following options are available:

      -h      Print this menu.

      -v      Verbose mode. Prints additional information to stdout if available.

      -c      Prints the commit hash instead of the detected version to stdout.

EXAMPLES
      Detects previous version, printing additional information if available.

          ./detectPreviousVersion.sh -v

NOTES
      If most recent tag is not valid by semantic versioning standards, you will have to prime the
      repository by tagging it appropriatley. Use '0.0.0' if in doubt. The version iteration
      script will automatically derive the correct version for the repository based on gitflow
      branch names.
"

printHelp() {
  echo -e "$help" >&2
}

# --------------------------------------------------------------------------------------------------
# Sanity (1/2)
# --------------------------------------------------------------------------------------------------

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "\e[01;31mFATAL\e[00m: This is not a git repository!\n"
fi

# --------------------------------------------------------------------------------------------------
# Arguments
# --------------------------------------------------------------------------------------------------

OPTIND=1
while getopts "hvc" opt; do
  case $opt in
    h)
      printHelp
      exit 0
      ;;
    v)
      arg_v='set'
      ;;
    c)
      arg_c='set'
      ;;
    *)
      echo -e "\e[01;31mERROR\e[00m: Invalid argument!"
      printHelp
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# --------------------------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------------------------

tsCmd='date --utc +%FT%T.%3NZ'
semverRegex="^[v]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-([0-9A-Za-z]+))?(\\+((([1-9])|([1-9][0-9]+))))?$"

relative_path="$(dirname "${BASH_SOURCE[0]}")"
dir="$(realpath "${relative_path}")"

lastVersion=$(git for-each-ref --sort=creatordate --format '%(refname:lstrip=2)' refs/tags | grep -E "$semverRegex" | tail -n 1)

# --------------------------------------------------------------------------------------------------
# Sanity (2/2)
# --------------------------------------------------------------------------------------------------

if [[ "$lastVersion" == '' ]]; then
  [[ -n $arg_v ]] && echo -e "[$(${tsCmd})] INFO: No previous version detected. Initializing at '0.0.0'.\n"
  lastVersion='0.0.0'
  lastVersionCommitHash=$(git rev-list --max-parents=0 HEAD)
else
  if ! bash -c "${dir}/validateSemver.sh -v9 $lastVersion"; then
    exit 1
  else
    lastVersionCommitHash=$(git rev-list -n 1 "$lastVersion")
    # Ensure lastVersion does not include a leading [vV]
    lastVersion=$(bash -c "${dir}/validateSemver.sh -v9p full $lastVersion")
  fi
fi

# --------------------------------------------------------------------------------------------------
# Main Operations
# --------------------------------------------------------------------------------------------------

if [[ -n $arg_c ]]; then
  echo "$lastVersionCommitHash"
else
  echo "$lastVersion"
fi
