# Github Action - AutoVer

Automatically determine the [semantic version](https://semver.org/) based on merge history (not commit messages), with MINIMAL discipline dependencies.

This is accomplished by counting the merges for 'enhancement/.\*', 'feature/.\*', 'bugfix/.\*', 'hotfix/.\*' branches into either the 'main' or 'master' branch.

## Appropriate Use Cases

This action is _most_ suitable for git projects with the following operational design:

- Each merge is intended to produce an artifact.
- Each artifact is potentially releasabe.

This action is _not_ suitable for projects requiring pre-release, beta, etc., type fields. Such projects should depend upon their own language native tooling.

This action is _not_ suitable for projects requiring version numbers to be planned and orchestrated ahead of time.

## Version Format

Versions are returned only in the following format:
'MAJOR.MINOR.PATCH'.

## Major Increments

MAJOR version increments depend upon manual intervention to trigger as it is not practical to automatically detect either major refactoring or _accepted/planned_ breaking changes to a product. Human input _informs_ the tool of such MAJOR increment qualifying scenarios.

This increment can be accomplished in one of the following ways:

1. Push a commit message containing: '+semver: [major|breaking]'. For example:

        git commit --allow-empty -m "+semver: major"
        git push

2. Push the MAJOR tag manually. That this is the _less desirable_ option as it will require the merge of a qualifying branch to iterate the version number, making the first possible version that could be produced 'n.0.1'. Assuming successful build and testing.

        git tag 1.0.0
        git push --tags

## Version Increment Logic

For those interested, here's some pseudo code:

    lastMajor = Extract from previous git tag (why option 1 is recommended)
    lastMinor = Extract from previous git tag
    lastPatch = Extract from previous git tag
    IF no previous git tag; THEN
        MAJOR = 0
        MINOR = 0
        PATCH = 0
    IF major increment indicator; THEN
        MAJOR = lastMajor + 1
        MINOR = 0
        PATCH = 0
    ELSEIF merged feature/.* or enhancement/.* branches; THEN
        MAJOR = lastMajor
        MINOR = lastMinor + count of merged branches
        PATCH = 0
    ELSEIF merged bugfix/.* or hotfix/.* branches; THEN
        MAJOR = lastMajor
        MINOR = lastMinor
        PATCH = lastPatch + count of merged branches

## Discipline Dependencies

This action depends only on the following _branch naming scheme_ being observed.

| Branch Name    | Increment | Description                            |
| -------------  | --------- | -------------------------------------- |
| feature/.*     | Minor     | Product features.                      |
| enhancement/.* | Minor     | Product enhancements.                  |
| **fix/.***     | Patch     | Product fixes                          |
| bugfix/.*      | Patch     | You should use fix.                    |
| hotfix/.*      | Patch     | Are you from the past?                 |
| ops/.*         | Patch     | Enables ops changes to trigger builds. |

For example, the name of the branch for a new awesome feature named Awesome Feature, might be: 'feature/awesome_feature'.

## [Known|Non]-Issues

- If both 'main' and 'master' branches exist remotely: FAIL
  - This will not be changed.
- Branches merged not conforming to the above branch naming scheme will result in a failed version detection.

## Future Enhancements

PR's welcome...

- Specifying custom branch names to indicate MINOR and PATCH versions.
- Subdirectory specific versioning.
