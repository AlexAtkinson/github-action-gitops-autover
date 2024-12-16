#!/usr/bin/env bash
# test.sh

function printHeading () {
    txt="$@";
    printf "\n\e[01;39m${txt}\e[0m ";
    printf '\n%*s' "$((${COLUMNS}-$((${COLUMNS}-$(wc -c<<<$txt)+1))))" | tr ' ' -;
    printf '\n'
}

relative_path="$(dirname "${BASH_SOURCE[0]}")"
dir="$(realpath "${relative_path}")"

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
    echo -e "\e[01;31mERROR\e[0m: 591 - Unsupported origin host."
    exit 1
  ;;
esac


# TEST: Repo Versioning

## Activities

# Tests:
# - Repo Versioning
# - Diectory Versioning
# - x Minor Increments
# - x Patch Increments



printHeading "Repo: Previous Version:"
scripts/detectPreviousVersion.sh

printHeading "Repo: New Version:"
scripts/detectNewVersion.sh || true

exit
# TEST: Directory-specific Versioning
TEST_DIR=$(openssl rand -base64 128 | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
mkdir -p ${TEST_DIR}/{a..c}

git add $TEST_DIR
git commit -m "$merge_string - Add test dir."


touch ${TEST_DIR}/{a..c}/foo
git commit -m "$merge_string - Add foo"


# for i in {1..9}; do
#   echo $i
# done

# RESET GIT: Discard changes.
# git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)
rm -rf ${TEST_DIR}
