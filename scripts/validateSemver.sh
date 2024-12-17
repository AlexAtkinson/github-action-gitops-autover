#!/usr/bin/env bash
# --------------------------------------------------------------------------------------------------
# validateSemver.sh
#
# Description
#     Validates semver.
#
# --------------------------------------------------------------------------------------------------
# Help
# --------------------------------------------------------------------------------------------------

help="\

NAME
      validateSemver.sh

SYNOPSIS
      ${0##*/} [-hpv9] <version>

DESCRIPTION
      Validates the schema of a provided version string against the semantic versioning standard.
      Returns an exit code of 0 or 1 by default.

      Matches against the full semantic versioning schema by detault. See -9 for CICD modifer.

          (v)[Major].[Minor].[Patch](-PRERELEASE)(+BUILD)

              PRERELEASE      A string containing prerelease info.

              BUILD           An integer specififying the build number.


      The following options are available:

      -h      Print this menu.

      -p      Print the supplied version, whole or in part, if it's found to be valid.
                    full      Print the full version string
                    major     Print only the Major version number
                    minor     Print only the Minor version number
                    patch     Print only the Patch version number
                    prere     Print only the prerelease verstion string
                    build     Print only the build number

      -v      Verbose mode. Prints additional information to stdout if available.

      -9      Agile CICD mode. Matches against the agile (everything is potentially releasable) schema:

                  (v)[Major].[Minor].[Patch]

      -m      Enables mono-repo mode, allowing matching against semvers prefixed with
              a product name. Eg: 'cool-app_1.2.3'

      -n      The product name to match against. EG: 'bob' would match tags like 'bob_1.2.3'.

      -d      The directory of the product to version. EG: 'path/to/bob'.

EXAMPLES
      The following returns an exit code of 0, as the supplied version is Agile CICD compliant.

          ./validateSemver.sh -9 2.23.4

      The following returns an exit code of 1, due to the tailing 'x', and prints an error to stdout.

          ./validateSemver.sh -v v4.10.33-develop+2342x

WARNING
      The inclusion of a leading [vV] is depricated. This tool will strip the character if found so
      that future version tags will not include it.
"

printHelp() {
  echo -e "$help" >&2
}

# --------------------------------------------------------------------------------------------------
# Sanity
# --------------------------------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
  printHelp
  exit 1
fi

# --------------------------------------------------------------------------------------------------
# Arguments
# --------------------------------------------------------------------------------------------------

OPTIND=1
while getopts "hp:v9mn:d:" opt; do
  case $opt in
    h)
      printHelp
      exit 0
      ;;
    p)
      arg_p='set'
      arg_p_val="$OPTARG"
      ;;
    v)
      arg_v='set'
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

# --------------------------------------------------------------------------------------------------
# Functions
# --------------------------------------------------------------------------------------------------

function validateSemver {
  local version=$1
  version=${version##*_}
  version=${version##*-}
  [[ "$version" =~ ^[vV]* ]] && version=${version//^[vV]/""/}
  if [[ "$version" =~ $semverRegex ]]; then
    local major=${BASH_REMATCH[1]}
    local minor=${BASH_REMATCH[2]}
    local patch=${BASH_REMATCH[3]}
    local prere=${BASH_REMATCH[5]}
    local build=${BASH_REMATCH[7]}
    if [[ -n $arg_p ]]; then
      case "$arg_p_val" in
        full) echo "${version}"
        ;;
        major) echo "${major}"
        ;;
        minor) echo "${minor}"
        ;;
        patch) echo "${patch}"
        ;;
        prere) echo "${prere}"
        ;;
        build) echo "${build}"
        ;;
      esac
    fi
  else
    [[ -z $arg_9 && -n $arg_v ]] && echo -e "[$(${tsCmd})] \e[01;31mFATAL\e[00m: '$version' does not match the semver schema: '(v)[Major].[Minor].[Patch](-PRERELEASE)(+BUILD)'!\n"
    [[ -n $arg_9 && -n $arg_v ]] && echo -e "[$(${tsCmd})] \e[01;31mFATAL\e[00m: '$version' does not match the semver schema: '(v)[Major].[Minor].[Patch]'!\n"
    [[ -n $arg_9 && -n $arg_v && -n $arg_m ]] && echo -e "[$(${tsCmd})] \e[01;31mFATAL\e[00m: '$version' does not match the semver schema: '[product_name][-_](v)[Major].[Minor].[Patch]'!\n"
    exit 1
  fi
}

# --------------------------------------------------------------------------------------------------
# Main Operations
# --------------------------------------------------------------------------------------------------

validateSemver "$1"
