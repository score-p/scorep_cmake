# has to run in project mode to register targets
cmake_minimum_required(VERSION 3.20)
project(
    TestAuto
    DESCRIPTION "Test AUTO argument"
    LANGUAGES C
)
find_package(OpenMP REQUIRED)

add_library(lib1 STATIC empty.c)
add_library(lib2 STATIC empty.c)
add_library(lib3 STATIC empty.c)
add_library(lib4 SHARED empty.c)

target_link_libraries(lib4 PRIVATE lib3)
target_link_libraries(lib3 PUBLIC lib2)
target_link_libraries(lib3 INTERFACE lib1)
target_link_libraries(lib2 PUBLIC lib1)
target_link_libraries(lib1 PRIVATE OpenMP::OpenMP_C)

include(ScorePUtilities)
find_package(ScoreP 0.0.0.1 EXACT REQUIRED)
scorep_instrument(lib4 LANGS C CXX ARGUMENTS "--user" AUTO)

include("${CMAKE_CURRENT_LIST_DIR}/../utils.cmake")
foreach(target lib1 lib2 lib3)
    foreach(lang C CXX)
        get_target_property(launcher "${target}" "${lang}_COMPILER_LAUNCHER")
        _check_lists_equal("${launcher}" "launcher-NOTFOUND")
        get_target_property(launcher "${target}" "${lang}_LINKERLAUNCHER")
        _check_lists_equal("${launcher}" "launcher-NOTFOUND")
    endforeach()
endforeach()

get_target_property(launcher lib4 C_COMPILER_LAUNCHER)
_check_lists_equal("${launcher}" "${SCOREP_EXECUTABLE};--user;--io=posix;--thread=omp")
get_target_property(launcher lib4 C_LINKER_LAUNCHER)
_check_lists_equal("${launcher}" "${SCOREP_EXECUTABLE};--user;--io=posix;--thread=omp")
get_target_property(launcher lib4 CXX_COMPILER_LAUNCHER)
_check_lists_equal("${launcher}" "${SCOREP_EXECUTABLE};--user;--io=posix")
get_target_property(launcher lib4 CXX_LINKER_LAUNCHER)
_check_lists_equal("${launcher}" "${SCOREP_EXECUTABLE};--user;--io=posix")
