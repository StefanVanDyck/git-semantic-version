#!/usr/bin/env bash
set -e -o pipefail
# This script determines what the current version should be based on previous git tags and new commit messages.
# The execution should result in outputting the to be released version to stdout.
# This allows you to use it from any shell script like so VERSION=$(./.version)
# All other info messages are piped to stderr for debugging purposes.

##### Default parameters #####
# Used as a prefix for tags, usefule for mon-repo things
COMPONENT=${COMPONENT:=""}
PATHS=${PATHS:=""}

# The string to check for inside of any commit messages.
MAJOR_BUMP_MESSAGE=${MAJOR_BUMP_MESSAGE:="\[bump_version+major\]"}
MINOR_BUMP_MESSAGE=${MINOR_BUMP_MESSAGE:="\[bump_version+minor\]"}
IGNORE_MESSAGE=${IGNORE_MESSAGE:="\[bump_version+ignore\]"}
POC_RELEASE_BRANCH_PREFIX=${POC_RELEASE_BRANCH_PREFIX:="poc-release/"}

# Check if the current branch starts with the PoC release prefix and if so, return the reset of the branch name as a version
_CURRENT_BRANCH_IS_POC_RELEASE=$(git rev-parse --abbrev-ref HEAD | grep -s "$POC_RELEASE_BRANCH_PREFIX" || true)
if [ -n "${_CURRENT_BRANCH_IS_POC_RELEASE}" ]; then
  echo >&2 "Branch starting with poc-release/, using branch name as version."
  echo -n "${_CURRENT_BRANCH_IS_POC_RELEASE#$POC_RELEASE_BRANCH_PREFIX}"
  exit 0
fi

# In case we want to version sub-components we need to alter the git version tag prefix
if [ -n "${COMPONENT}" ]; then
  echo >&2 "Versioning a sub-component ${COMPONENT}."
  _COMPONENT_VERSION_PREFIX="${COMPONENT}-v"
else
  _COMPONENT_VERSION_PREFIX="v"
fi

# Check if the current commit already has a tag, in which case, use that one
_VERSION_TAG_ON_CURRENT_COMMIT=$(git tag --points-at HEAD | grep -s -e "^${_COMPONENT_VERSION_PREFIX}[0-9]*.[0-9]*.[0-9]*" || true)
if [ -n "${_VERSION_TAG_ON_CURRENT_COMMIT}" ]; then
  echo >&2 "Found a tag on the current commit, using that one."
  echo "number_of_changes_since_last_tag=0"
  echo "previous_version=${_VERSION_TAG_ON_CURRENT_COMMIT#$_COMPONENT_VERSION_PREFIX}"
  echo "new_version=${_VERSION_TAG_ON_CURRENT_COMMIT#$_COMPONENT_VERSION_PREFIX}"
  exit 0
fi

# Get the most recent git tag
_LAST_VERSION_TAG="$(git describe --tags --abbrev=0 --match="${_COMPONENT_VERSION_PREFIX}[0-9]*.[0-9]*.[0-9]*" || true)"
if [ -z "${_LAST_VERSION_TAG}" ]; then
  echo >&2 "No tags found defaulting to 0.0.1"
  echo "number_of_changes_since_last_tag="
  echo "previous_version="
  echo "new_version=0.0.1"
  exit 0
fi

_LAST_VERSION="${_LAST_VERSION_TAG#$_COMPONENT_VERSION_PREFIX}" # remove leading v
_CURRENT_VERSION=(${_LAST_VERSION//./ })                    # replace points, split into array
echo >&2 "Last version = ${_CURRENT_VERSION[0]}.${_CURRENT_VERSION[1]}.${_CURRENT_VERSION[2]}"

_PATHS_ARGUMENT=""
if [ -n "${PATHS}" ]; then
  _PATHS_ARGUMENT="-- ${PATHS}"
fi

# Look for strings in commit messages since last tag
# Fetch commits in one go; restrict to PATHS if provided
_RAW_COMMITS="$(git log "${_LAST_VERSION_TAG}..HEAD" --oneline ${_PATHS_ARGUMENT} || true)"

# Normalize configured markers by removing backslashes so we can use fixed-string matching
# This allows the defaults like \[bump_version+major\] to match literal commit messages like [bump_version+major]
_MAJOR_MARKER="${MAJOR_BUMP_MESSAGE//\\}"
_MINOR_MARKER="${MINOR_BUMP_MESSAGE//\\}"
_IGNORE_MARKER="${IGNORE_MESSAGE//\\}"

# Filter out commits that contain the ignore marker so they are excluded from versioning
if [ -z "${_RAW_COMMITS}" ]; then
  _COMMITS=""
else
  _COMMITS="$(printf '%s\n' "${_RAW_COMMITS}" | grep -vFi -- "${_IGNORE_MARKER}" || true)"
fi

# If there are no non-ignored commits we need to distinguish two situations:
# 1) There were no commits at all in the (optional) PATHS -> treat like "no bump marker found" and bump patch
# 2) There were commits but all of them contained the ignore marker -> ignore those changes and return the previous version
if [ -z "${_COMMITS}" ]; then
  if [ -n "${_RAW_COMMITS}" ]; then
    echo >&2 "All commits since last tag were ignored by ignore marker, returning previous version."
    echo "number_of_changes_since_last_tag=0"
    echo "previous_version=${_LAST_VERSION}"
    echo "new_version=${_LAST_VERSION}"
    exit 0
  else
    echo >&2 "No commits in relevant paths since last tag, bumping patch version."
    _CURRENT_VERSION[2]=$((_CURRENT_VERSION[2] + 1))
  fi
else
  # Helper: return commits that match the given pattern (case-insensitive, fixed string)
  _matches() {
    local pattern="$1"
    printf '%s\n' "${_COMMITS}" | grep -iF -- "${pattern}" || true
  }

  if [ -n "$( _matches "${_MAJOR_MARKER}" )" ]; then
    echo >&2 "Found ${_MAJOR_MARKER} in commit messages, bumping major version."
    echo >&2 "$( _matches "${_MAJOR_MARKER}" )"
    _CURRENT_VERSION[0]=$((_CURRENT_VERSION[0] + 1))
    _CURRENT_VERSION[1]=0
    _CURRENT_VERSION[2]=0
  elif [ -n "$( _matches "${_MINOR_MARKER}" )" ]; then
    echo >&2 "Found ${_MINOR_MARKER} in commit messages, bumping minor version."
    echo >&2 "$( _matches "${_MINOR_MARKER}" )"
    _CURRENT_VERSION[1]=$((_CURRENT_VERSION[1] + 1))
    _CURRENT_VERSION[2]=0
  else
    echo >&2 "Found no bump in commit messages, bumping patch version."
    _CURRENT_VERSION[2]=$((_CURRENT_VERSION[2] + 1))
  fi
fi
echo >&2 "Current version = ${_CURRENT_VERSION[0]}.${_CURRENT_VERSION[1]}.${_CURRENT_VERSION[2]}"

# Count non-ignored commits and return result to stdout
_NUMBER_OF_CHANGES=$(printf '%s\n' "${_COMMITS}" | sed '/^$/d' | wc -l)
echo "number_of_changes_since_last_tag=${_NUMBER_OF_CHANGES}"
echo "previous_version=${_LAST_VERSION}"
echo "new_version=${_CURRENT_VERSION[0]}.${_CURRENT_VERSION[1]}.${_CURRENT_VERSION[2]}"
