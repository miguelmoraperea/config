#!/usr/bin/env ./test/libs/bats/bin/bats
load 'test/libs/bats-support/load'
load 'test/libs/bats-assert/load'

readonly SCRIPT="./reformat.sh"

@test "Test converting spaces to underscore" {
    source ${SCRIPT}
    run generate_new_file_names "hello world"
    assert_output hello_world
    assert_success
}

@test "Test converting uppercase to lowercase" {
    source ${SCRIPT}
    run generate_new_file_names "HeLlo WorlD"
    assert_output hello_world
    assert_success
}

@test "Test extensions to lowercase" {
    source ${SCRIPT}
    run generate_new_file_names "HeLlo WorlD.JPG"
    assert_output hello_world.jpg
    assert_success
}

@test "Test do nothing to other symbols" {
    source ${SCRIPT}
    run generate_new_file_names "He!!o W#rlD.JPG"
    assert_output he!!o_w#rld.jpg
    assert_success
}

@test "Test do nothing to numbers" {
    source ${SCRIPT}
    run generate_new_file_names "He11o W0rlD.JPG"
    assert_output he11o_w0rld.jpg
    assert_success
}

@test "Test multiple file names at the same time" {
    source ${SCRIPT}
    run generate_new_file_names Hello World.JPG "0ther F1Le name.json"

    expected=$( cat <<- 'EOF'
			hello
			world.jpg
			0ther_f1le_name.json
		EOF
    )

    assert_output "${expected}"
    assert_success
}
