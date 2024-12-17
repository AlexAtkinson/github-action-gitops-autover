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

      -m      Enables mono-repo mode, allowing matching against semvers prefixed with
              a product name. Eg: 'cool-app_1.2.3'

      -n      The product name to match against. EG: 'bob' would match tags like 'bob_1.2.3'.

      -d      The directory of the product to version. EG: 'path/to/bob'.

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
while getopts "hv9cmn:d:" opt; do
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
    9)
      arg_9='set'
      ;;
    m)
      arg_m='set'
      arg_opts="$arg_opts -m"
      ;;
    n)
      arg_n='set'
      arg_n_val="$OPTARG"
      arg_opts="$arg_opts -n $OPTARG"
      ;;
    d)
      arg_d='set'
      arg_d_val="$OPTARG"
      arg_d_opt="--full-history"
      arg_opts="$arg_opts -d $OPTARG"
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

if [[ -n $arg_9 ]]; then
  semverRegex="^[v]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"
  [[ -n $arg_m ]] && semverRegex="([0-9A-Za-z]+)?[_-]?[v]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"
else
  semverRegex="^[v]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-([0-9A-Za-z]+))?(\\+((([1-9])|([1-9][0-9]+))))?$"
  [[ -n $arg_m ]] && semverRegex="^([0-9A-Za-z]+)?[_-]?[v]?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-([0-9A-Za-z]+))?(\\+((([1-9])|([1-9][0-9]+))))?$"
fi

relative_path="$(dirname "${BASH_SOURCE[0]}")"
dir="$(realpath "${relative_path}")"

lastVersion=$(git for-each-ref --sort=creatordate --format '%(refname:lstrip=2)' refs/tags | grep -E "$semverRegex" | tail -n 1)
# Support mono-repos where a product name is specified.
[[ -n $arg_n ]] && lastVersion=$(git for-each-ref --sort=creatordate --format '%(refname:lstrip=2)' refs/tags | grep "$arg_n_val" | grep -E "$semverRegex" | tail -n 1)

# --------------------------------------------------------------------------------------------------
# Sanity (2/2)
# --------------------------------------------------------------------------------------------------

if [[ "$lastVersion" == '' ]]; then
  [[ -n $arg_v && -z $arg_n ]] && echo -e "[$(${tsCmd})] INFO: No previous version detected. Initializing at '0.0.0'.\n"
  [[ -n $arg_v && -n $arg_n ]] && echo -e "[$(${tsCmd})] INFO: No previous version detected. Initializing at '${arg_n_val}_0.0.0'.\n"
  lastVersion='0.0.0'
  lastVersionCommitHash=$(git rev-list --max-parents=0 HEAD)
else
  if ! bash -c "${dir}/validateSemver.sh -v9 $arg_opts $lastVersion"; then
    exit 1
  else
    lastVersionCommitHash=$(git rev-list -n 1 "$lastVersion")
    # Ensure lastVersion does not include a leading [vV]
    lastVersion=$(bash -c "${dir}/validateSemver.sh -v9p full $arg_opts $lastVersion")
  fi
fi

[[ -n $arg_n ]] && lastVersion="${arg_n_val}_${lastVersion}"

# --------------------------------------------------------------------------------------------------
# Main Operations
# --------------------------------------------------------------------------------------------------

if [[ -n $arg_c ]]; then
  echo "$lastVersionCommitHash"
else
  echo "$lastVersion"
fi
