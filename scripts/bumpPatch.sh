#!/usr/bin/env bash
# --------------------------------------------------------------------------------------------------
# bumpPatch.sh
#
# Description
#     Bumps patch version n times.
#     This simplifies debugging and fixing invalid branch name merges that require a build.
#     This is accomplished by creating the appropriate branch n times, merging, and deleting the branch.
#
# --------------------------------------------------------------------------------------------------

# Detect remote main branch
main_remote=$(git branch --list main)
if [[ -n ${main_remote} ]]; then
  main_remote=true
  main="main"
fi
master_remote=$(git branch --list master)
if [[ -n ${master_remote} ]]; then
  master_remote=true
  main="master"
fi
if [[ $main_remote == true && $master_remote == true ]]; then
  echo "ERROR: Both main and master branches exist remotely."
  exit 1
fi
if [[ $main_remote != true && $master_remote != true ]]; then
  echo "ERROR: Neither main or master branch exist remotely."
  exit 1
fi

# Set commit merge_string by vendor
origin=$(git config --get remote.origin.url)
[[ $origin =~ github ]] && origin_host=github
[[ $origin =~ gitlab ]] && origin_host=gitlab
[[ $origin =~ bitbucket ]] && origin_host=bitbucket

merge_branch="bugfix/XX-BUMP_COUNT_PatchBump"

case "$origin_host" in
  github)
    merge_string="Merge pull request #NA from org/bugfix/XX-BUMP_COUNT_PatchBump"
  ;;
  gitlab)
    merge_string="Merge branch 'bugfix/XX-BUMP_COUNT_PatchBump' into '$main'"
  ;;
  bitbucket)
    merge_string="Merged in bugfix/XX-BUMP_COUNT_PatchBump (pull request #NA)"
  ;;
  *)
    echo -e "\e[01;31mERROR\e[0m: Unsupported origin host."
    exit 1
  ;;
esac

# Bump version
if [[ $# -eq 0 ]] ; then
  echo "You must specify how many feature branches you want to create, merge, and delete."
  exit 1
fi

for i in $(eval echo "{1..$1}") ; do
  merge_branch_n=${merge_branch//BUMP_COUNT/$i/}
  merge_string_n=${merge_string//BUMP_COUNT/$i/}
  git checkout $main
  git checkout -b "$merge_branch_n"
  git commit --allow-empty -m "Patch Version Bump"
  git checkout $main
  git merge --no-ff "$merge_branch_n" --no-edit -m "${merge_string_n}"
  git branch -d "$merge_branch_n"
done
