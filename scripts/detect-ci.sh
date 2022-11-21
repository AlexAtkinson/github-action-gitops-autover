#!/usr/bin/env bash
# detect-ci.sh
# ------------------------------------------------------------------------------
#
# Description:
#   Attempts to detect the vendor for a CI environment.
#
# Notes:
#   - Not every CI provider sets 'CI=true'
#   - Not every CI provider sets '<vendor name>=true'
#     - SHOUT OUT: Thank you to the good ones.
#   - If it took more than 60s of searching for a vendor-specific envar to enable detection, they weren't included.
#     - codeship uses 'CI_NAME', which is rough enough... except...
#       - it would set a nice standard for CI kits.
#
# Usage:
#   - You can copy/paste this script wherever, or source it remotely.
#     See: https://gist.github.com/AlexAtkinson/6accc3a7fb9b61ec488146c1cf2cf527
#
# ------------------------------------------------------------------------------

# Uses CI_NAME_X to avoid clobbering CI_NAME
[[ -n $GITHUB_ACTIONS ]]         && CI_NAME_X="github"
[[ -n $BITBUCKET_BUILD_NUMBER ]] && CI_NAME_X="bitbucket"
[[ -n $TRAVIS ]]                 && CI_NAME_X="travis"
[[ -n $GITLAB_CI ]]              && CI_NAME_X="gitlab"
[[ -n $JENKINS_HOME ]]           && CI_NAME_X="jenkins"
[[ -n $TEAMCITY_VERSION ]]       && CI_NAME_X="teamcity"
[[ -n $BUDDY ]]                  && CI_NAME_X="buddy"
[[ -n $GO_PIPELINE_COUNTER ]]    && CI_NAME_X="gocd"
[[ -n $SEMAPHORE ]]              && CI_NAME_X="semaphore"
[[ -n $CM_BUILD_ID ]]            && CI_NAME_X="codemagic"
[[ -n $BITRISE_IO ]]             && CI_NAME_X="bitrise"
[[ -n $DRONE ]]                  && CI_NAME_X="drone"
[[ -n $APPVEYOR ]]               && CI_NAME_X="appveyor"
[[ -n $GAE_APPLICATION ]]        && CI_NAME_X="appengine"
[[ -n $JFROG_CLI_BUILD_NUMBER ]] && CI_NAME_X="jfrog"
[[ -n $BUILDKITE ]]              && CI_NAME_X="buildkite"
[[ -n $CF_BUILD_ID ]]            && CI_NAME_X="codefresh"
[[ -n $WEBAPPIO ]]               && CI_NAME_X="webappio"
[[ $CI_NAME == 'codeship' ]]     && CI_NAME_X="codeship"

# CI_NAME has not been detected at this point.
# Check to see if the _sometimes_ used 'CI' envar is set.
[[ -n $CI && -z $CI_NAME_X ]]    && CI_NAME_X="unknown"

[[ -z $CI && -z $CI_NAME_X ]]    && CI_NAME_X=""

echo "$CI_NAME_X"
