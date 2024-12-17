#!/usr/bin/env bash
# test.sh

TEST="test_$(date --utc +"%s")"
trap 'rm -rf $TEST; \
      git reset --hard $STARTING_COMMIT;' EXIT
      #git reset HEAD~$TEST_COMMIT_COUNT;' EXIT

STARTING_COMMIT=$(git rev-parse HEAD)

TEST_COMMIT_COUNT=0

function printHeading () {
    txt="$@";
    printf "\n\e[01;39m${txt}\e[0m ";
    printf '\n%*s' "$((${COLUMNS}-$((${COLUMNS}-$(wc -c<<<$txt)+1))))" | tr ' ' -;
    printf '\n'
}

function add_history() {
  if [[ $# -ne 3 ]] && [[ $# -ne 4 ]]; then echo "ERROR: Exactly 3 or 4 arguments required!"; return 1; fi
  DIR="$1"
  COUNT="$2"
  BRANCH_TYPE="$3"
  MAJOR="$4"
  cd "$DIR"
  for i in $(seq 1 $COUNT); do
    TEST_FILE="${i}_$(date +"%s%6N")"
    touch $TEST_FILE
    git add "$TEST_FILE" >/dev/null 2>&1
    [[ -n $MAJOR ]] && git commit -m "+semver major $TEST" >/dev/null 2>&1
    git commit -m "Merge pull request #9999 from AlexAtkinson/$BRANCH_TYPE/${TEST}_$i" >/dev/null 2>&1
  done
  cd - >/dev/null 2>&1
}

function test_previous() {
  if [[ $# -lt 3 ]]; then echo "ERROR: At least 3 arguments required!"; return 1; fi
  TEST_TYPE="${1:-Repository}" # Repository, Directory
  DIRECTORY="${2:-./}"
  ASSERTION="$3"
  COMMENT="${@:4}"; [[ -z $COMMENT ]] && COMMENT="No Comment"
  if [[ "$TEST_TYPE" == "Repository" ]]; then
    echo -e "\e[01;39m$TEST_TYPE: Previous Version ($COMMENT)\e[0m"
    TEST_OUTPUT=$(scripts/detectPreviousVersion.sh)
    if grep -q "$ASSERTION" <<<$TEST_OUTPUT; then RESULT="\e[01;32mOK\e[0m"; else RESULT="\e[01;31mFAIL\e[0m"; FAILURE="TRUE"; fi
    echo -e " $RESULT - $TEST_OUTPUT"
  fi
  if [[ "$TEST_TYPE" == "Directory" ]]; then
    echo -e "\e[01;39m$TEST_TYPE - $DIRECTORY: Previous Version ($COMMENT)\e[0m"
    TEST_OUTPUT=$(scripts/detectPreviousVersion.sh -d "$DIRECTORY" -n "${DIRECTORY##*/}")
    if grep -q "$ASSERTION" <<<$TEST_OUTPUT; then RESULT="\e[01;32mOK\e[0m"; else RESULT="\e[01;31mFAIL\e[0m"; FAILURE="TRUE"; fi
    echo -e " $RESULT - $TEST_OUTPUT"
  fi
}

function test_new() {
  if [[ $# -lt 3 ]]; then echo "ERROR: At least 3 arguments required!"; return 1; fi
  TEST_TYPE="${1:-Repository}" # Repository, Directory
  DIRECTORY="${2:-./}"
  ASSERTION="$3"
  COMMENT="${@:4}"; [[ -z $COMMENT ]] && COMMENT="No Comment"
  if [[ "$TEST_TYPE" == "Repository" ]]; then
    echo -e "\e[01;39m$TEST_TYPE: New Version ($COMMENT)\e[0m"
    TEST_OUTPUT=$(scripts/detectNewVersion.sh)
    if grep -q "$ASSERTION" <<<$TEST_OUTPUT; then RESULT="\e[01;32mOK\e[0m"; else RESULT="\e[01;31mFAIL\e[0m"; FAILURE="TRUE"; fi
    echo -e " $RESULT - $TEST_OUTPUT"
  fi
  if [[ "$TEST_TYPE" == "Directory" ]]; then
    echo -e "\e[01;39m$TEST_TYPE - $DIRECTORY: New Version ($COMMENT)\e[0m"
    TEST_OUTPUT=$(scripts/detectNewVersion.sh -d "$DIRECTORY" -n "${DIRECTORY##*/}")
    if grep -q "$ASSERTION" <<<$TEST_OUTPUT; then RESULT="\e[01;32mOK\e[0m"; else RESULT="\e[01;31mFAIL\e[0m"; FAILURE="TRUE"; fi
    echo -e " $RESULT - $TEST_OUTPUT"
  fi
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

printHeading Running Test: $TEST

echo NOTE: These tests are not committed.

mkdir -p $TEST/{A..C}

# Directory Test: A
# ASSERTIONS:
# - Previous version is: A_0.0.0
# - New Version is: ERROR: 599
test_previous "Repository" "./" "$(scripts/detectPreviousVersion.sh)"
test_new "Repository" "./" " 599"

test_previous "Directory" "$TEST/A" "A_0.0.0"
test_new "Directory" "$TEST/A" " 599"

test_previous "Directory" "$TEST/B" "B_0.0.0"
add_history "$TEST/B" 3 ops
test_new "Directory" "$TEST/B" "B_0.0.3" patches +3
git tag -a "B_0.0.3" -m "TAG"
test_previous "Directory" "$TEST/B" "B_0.0.3" previous version tagged
add_history "$TEST/B" 17 ops
test_new "Directory" "$TEST/B" "B_0.0.20" patches +17
git tag -d "B_0.0.3" >/dev/null 2>&1

test_previous "Directory" "$TEST/C" "C_0.0.0"
add_history "$TEST/C" 9 ops
test_new "Directory" "$TEST/C" "C_0.0.9" patches +9
git tag -a "C_0.0.9" -m "TAG"
test_previous "Directory" "$TEST/C" "C_0.0.9" previous version tagged
test_new "Directory" "$TEST/C" " 599"

add_history "$TEST/C" 5 feature
test_new "Directory" "$TEST/C" "C_0.5.0" features +5
git tag -a "C_0.5.0" -m "TAG"
add_history "$TEST/C" 19 ops
test_new "Directory" "$TEST/C" "C_0.5.19" patches +19
add_history "$TEST/C" 1 features major
test_new "Directory" "$TEST/C" "C_1.0.0" features +1 BREAKING
git tag -d "C_0.0.9" >/dev/null 2>&1
git tag -d "C_0.5.0" >/dev/null 2>&1

