#!/usr/bin/env bash
# --------------------------------------------------------------------------------------------------
# detectNewVersion.sh
#
# Description
#     Detects new version.
#
# --------------------------------------------------------------------------------------------------
# Source Detection
# --------------------------------------------------------------------------------------------------

sourced=0
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1
else # All other shells: examine $0 for known shell binary filenames
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|dash) sourced=1;; esac
fi

# --------------------------------------------------------------------------------------------------
# Help
# --------------------------------------------------------------------------------------------------

help="\

NAME
      ${0##*/}

SYNOPSIS
      ${0##*/} [-hv]

DESCRIPTION
      Detects the new version for the repository by analyzing the gitflow branch history since the
      previous version tag.
      Prints only the new version to stdout by default.

      The following options are available:

      -h      Print this menu.

      -e      Export detected new version to defined variable, if valid.

      -f      Forces a re-evaluation of the entire git history.

EXAMPLES
      The following detects the new version for the repo.

          ./detectNewVersion.sh

      The following detects the new version for the repo, and exports to the specified variable.

          . ./detectNewVersion.sh -e fooVar

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
while getopts "he:vf" opt; do
  case $opt in
    h)
      printHelp
      if [[ "$sourced" == 0 ]]; then
        exit 0
      else
        return 0
      fi
      ;;
    e)
      arg_e='set'
      arg_e_val="$OPTARG"
      ;;
    f)
      arg_f='set'
      ;;
    *)
      echo -e "\e[01;31mERROR\e[00m: Invalid argument!"
      printHelp
      if [[ "$sourced" == 0 ]]; then
        exit 0
      else
        return 0
      fi
      ;;
  esac
done
shift $((OPTIND-1))

# --------------------------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------------------------

IFS_BAK=$IFS
tsCmd='date --utc +%FT%T.%3NZ'

relative_path="$(dirname "${BASH_SOURCE[0]}")"
dir="$(realpath "${relative_path}")"

lastVersion=$(/usr/bin/env bash -c "${dir}/detectPreviousVersion.sh")
echo $lastVersion
lastVersionMajor=$(/usr/bin/env bash -c "${dir}/validateSemver.sh -p major $lastVersion")
echo $lastVersionMajor
lastVersionMinor=$(/usr/bin/env bash -c "${dir}/validateSemver.sh -p minor $lastVersion")
echo $lastVersionMinor
lastVersionPatch=$(/usr/bin/env bash -c "${dir}/validateSemver.sh -p patch $lastVersion")
echo $lastVersionPatch
lastVersionCommitHash=$(/usr/bin/env bash -c "${dir}/detectPreviousVersion.sh -c")
echo  $lastVersionCommitHash
lastCommitHash=$(git rev-parse HEAD)
echo $lastCommitHash
firstCommitHash=$(git rev-list --max-parents=0 HEAD)
echo $firstCommitHash

ci_name=$("${dir}/detect-ci.sh")
origin=$(git config --get remote.origin.url)

#origin=${ci_name:-origin}
# Executes in ANY CI so long as repo origin is one of the following.
# Uncomment origin override to restrict this.
[[ "$origin" =~ "git@github.com"* || "$ci_name" == "github" ]] && origin_host=github
[[ "$origin" =~ "git@gitlab.com"* || "$ci_name" == "gitlab" ]] && origin_host=gitlab
[[ "$origin" =~ "git@bitbucket.com"* || "$ci_name" == "bitbucket" ]] && origin_host=bitbucket

case "$origin_host" in
  github)
    merge_string="Merge pull request #"
    column=7
    field=2
  ;;
  gitlab)
    merge_string="Merge branch"
    column=4
    field=1
  ;;
  bitbucket)
    merge_string="Merged in"
    column=4
    field=1
  ;;
  *)
    echo -e "\e[01;31mERROR\e[0m: Unsupported origin host."
    exit 1
  ;;
esac

echo $merge_string

git log --pretty=oneline "${lastVersionCommitHash}".."${lastCommitHash}" | awk -v s="$merge_string" -v c="$column" -v f="$field" '$0 ~ s {print $c}'
echo 165
git log --pretty=oneline "${lastVersionCommitHash}".."${lastCommitHash}" | awk -v s="$merge_string" -v c="$column" -v f="$field" '$0 ~ s {print $c}' | awk -F'/' '{print $f}' | tr -d "'"
echo 167
git log --pretty=oneline "${lastVersionCommitHash}".."${lastCommitHash}" | awk -v s="$merge_string" -v c="$column" -v f="$field" '$0 ~ s {print $c}' | awk -F'/' '{print $f}' | tr -d "'" | grep -i '^enhancement$\|^feature$\|^fix$\|^hotfix$\|^bugfix$\|^ops$'
echo 169
# --------------------------------------------------------------------------------------------------
# Sanity (2/2)
# --------------------------------------------------------------------------------------------------

if [[ -n $arg_e ]]; then
  if [[ "$sourced" == 0 ]]; then
    echo -e "[$(${tsCmd})] \e[01;31mERROR\e[00m: You must source this script when specifying an environment variable! Eg: '. ./${0##*/} -e foo_ver'\n"
    exit 1
  fi
fi

IFS=$'\r\n'
if [[ -n $arg_f ]]; then
  for i in $(git log --pretty=oneline "${firstCommitHash}".."${lastCommitHash}" | awk -v s="$merge_string" -v c="$column" -v f="$field" '$0 ~ s {print $c}' | awk -F'/' '{print $f}' | tr -d "'" | grep -i '^enhancement$\|^feature$\|^fix$\|^hotfix$\|^bugfix$\|^ops$' | awk -F '\r' '{print $1}' | sort | uniq -c | sort -nr) ; do
    varname=$(echo "$i" | awk '{print $2}')
    varname=${varname,,}
    value=$(echo "$i" | awk '{print $1}')
    value=${value,,}
    declare count_"$varname"="$value"
  done
else
  for i in $(git log --pretty=oneline "${lastVersionCommitHash}".."${lastCommitHash}" | awk -v s="$merge_string" -v c="$column" -v f="$field" '$0 ~ s {print $c}' | awk -F'/' '{print $f}' | tr -d "'" | grep -i '^enhancement$\|^feature$\|^fix$\|^hotfix$\|^bugfix$\|^ops$' | awk -F '\r' '{print $1}' | sort | uniq -c | sort -nr) ; do
    varname=$(echo "$i" | awk '{print $2}')
    varname=${varname,,}
    value=$(echo "$i" | awk '{print $1}')
    value=${value,,}
    declare count_"$varname"="$value"
  done
fi
IFS=$IFS_BAK

if [[ -n $arg_f ]]; then
  true
else
  if [[ -z $count_feature && -z $count_enhancement && -z $count_fix && -z $count_bugfix && -z $count_hotfix && -z $count_ops ]]; then
    echo -e "\e[01;31mERROR\e[00m: No feature, enhancement, fix, bugfix, hotfix, or ops branches detected!"
    if [[ "$sourced" == 0 ]]; then
      exit 1
    else
      return 1
    fi
  fi
fi

# --------------------------------------------------------------------------------------------------
# Main Operations
# --------------------------------------------------------------------------------------------------

git log --pretty=oneline "$lastVersionCommitHash".."$lastCommitHash" | grep '+semver' | grep -q 'major\|breaking' && incrementMajor='true'

if [[ $incrementMajor == 'true' ]]; then
  newVersionMajor=$((lastVersionMajor + 1))
  newVersionMinor='0'
  newVersionPatch='0'
elif [[ -n $count_feature || -n $count_enhancement ]]; then
  newVersionMajor=$lastVersionMajor
  [[ -n $count_feature ]] && newVersionMinor=$((lastVersionMinor + count_feature))
  [[ -n $count_enhancement ]] && newVersionMinor=$((newVersionMinor + count_enhancement))
  newVersionPatch='0'
elif [[ -n $count_bugfix || -n $count_hotfix ]]; then
  newVersionMajor=$lastVersionMajor
  newVersionMinor=$lastVersionMinor
  [[ -n $count_bugfix ]] && newVersionPatch=$((lastVersionPatch + count_bugfix))
  [[ -n $count_hotfix ]] && newVersionPatch=$((newVersionPatch + count_hotfix))
fi

newVersion=$(/usr/bin/env bash -c "${dir}/validateSemver.sh -9p full $newVersionMajor.$newVersionMinor.$newVersionPatch")

if [[ -n $arg_e ]]; then
  export_var="$arg_e_val"
  eval "${export_var}=${newVersion}"
  export export_var
else
  echo -n "$newVersion"
fi
