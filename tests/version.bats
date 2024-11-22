#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

VERSION_SCRIPT="../../scripts/version.sh"

BATS_GIT_TEMP_FOLDER="tests/.version-test-temp"

setup() {
    rm -rf "${BATS_GIT_TEMP_FOLDER}"
    mkdir "${BATS_GIT_TEMP_FOLDER}"
    cd "${BATS_GIT_TEMP_FOLDER}"
    git init
    git config user.email "bats-test@deltaray.eu"
    git config user.name "Bats test"
    git commit -m "Initial commit" --allow-empty
}



@test "version given no tags" {
    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "version given a tag, but not preceded with version prefix" {
    git tag -a 1.2.3 -m "some comment"

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "version given a tag already set on commit, use that one" {
    git tag -a v1.2.3 -m "some comment"

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "1.2.3" ]
}

@test "version given a tag in previous commit, bump patch" {
    git tag -a v1.2.3 -m "some comment"
    git commit -m "Next commit" --allow-empty

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "1.2.4" ]
}

@test "version given a tag in previous commit with a bump minor message, bump minor" {
    git tag -a v1.2.3 -m "some comment"
    git commit -m "[bump_version+minor]" --allow-empty

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "1.3.0" ]
}


@test "version given a tag in previous commit with a bump major message, bump major" {
    git tag -a v1.2.3 -m "some comment"
    git commit -m "[bump_version+major]" --allow-empty

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "2.0.0" ]
}

@test "version given a component and no specific tags, then default" {
    git tag -a v1.2.3 -m "some comment"
    export COMPONENT=test

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}

@test "version given a component and a specific tag, then use that one" {
    git tag -a test-v1.2.3 -m "some comment"
    git tag -a v4.5.6 -m "some comment"
    export COMPONENT=test

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "1.2.3" ]
}


@test "version given a component and a specific tag on previous commit, then bump that one" {
    git tag -a test-v1.2.3 -m "some comment"
    git commit -m "no bumps" --allow-empty
    git tag -a v4.5.6 -m "some comment"
    export COMPONENT=test

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "1.2.4" ]
}

@test "version given no component but commit already tagged with sub-component tag, then ignore and use global version" {
    git tag -a test-v1.2.3 -m "some comment"

    run --separate-stderr ${VERSION_SCRIPT}

    echo "Status: $status"
    echo "Output: $output"
    echo "Stderr: $stderr"

    [ "$status" -eq 0 ]
    [ "$output" == "0.0.1" ]
}