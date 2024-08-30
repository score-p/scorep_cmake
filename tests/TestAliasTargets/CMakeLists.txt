# has to run in project mode to register targets
cmake_minimum_required(VERSION 3.20)
project(
    TestAliasTargets
    DESCRIPTION "Test handling of Alias Targets"
    LANGUAGES C
)

add_library(lib1 STATIC empty.c)
add_library(lib2 ALIAS lib1)
add_library(lib3 SHARED empty.c)
add_library(lib4 SHARED empty.c)
add_library(lib5 ALIAS lib4)

target_link_libraries(lib3 PRIVATE lib1)
target_link_libraries(lib4 PRIVATE lib2)
target_link_libraries(lib4 PRIVATE lib2)

include(ScorePUtilities)
scorep_mark(INSTRUMENT lib1 LANGS C ARGUMENTS "--user" AUTO)
scorep_determine_instrumentations("lib1;lib2;lib3;lib4;lib5")

find_package(ScoreP 0.0.0.1 EXACT REQUIRED)
scorep_discover_targets(targets)
scorep_enable("${targets}")

include("${CMAKE_CURRENT_LIST_DIR}/../utils.cmake")
foreach(target lib1 lib2 lib3 lib4 lib5)
    get_target_property(languages "${target}" SCOREP_LANGUAGES)
    _check_lists_equal("${languages}" "C")
    get_target_property(arguments "${target}" SCOREP_C_ARGUMENTS)
    _check_lists_equal("${arguments}" "--user;--io=posix")
    get_target_property(launcher "${target}" C_COMPILER_LAUNCHER)
    _check_lists_equal("${launcher}" "${SCOREP_EXECUTABLE};--user;--io=posix")
    get_target_property(launcher "${target}" C_LINKER_LAUNCHER)
    _check_lists_equal("${launcher}" "${SCOREP_EXECUTABLE};--user;--io=posix")
endforeach()
