cmake_minimum_required(VERSION 3.20)
project(
    "CUDA example"
    DESCRIPTION "Example for using Score-P with a CUDA application"
    LANGUAGES CUDA CXX
)

find_package(Boost "1.74" REQUIRED COMPONENTS "program_options")

option(ENABLE_SCOREP "Enable Score-P instrumentation" OFF)
if(ENABLE_SCOREP)
    include(ScorePUtilities)
else()
    function(scorep_mark)
    endfunction()
endif()

add_executable(fibonacci "fibonacci.cu")
target_link_libraries(fibonacci PRIVATE Boost::program_options)
set_property(TARGET fibonacci PROPERTY LINKER_LANGUAGE CXX)
scorep_mark(INSTRUMENT fibonacci LANGS CUDA CXX ARGUMENTS "--compiler" AUTO)

if(ENABLE_SCOREP)
    scorep_discover_targets(allTargets)
    scorep_determine_instrumentations("${allTargets}" COMPONENTS_VAR scorepComponents)
    scorep_infer_components(CUDA inferredComponents)
    list(APPEND scorepComponents ${inferredComponents})
    list(REMOVE_DUPLICATES scorepComponents)
    find_package(ScoreP REQUIRED COMPONENTS ${scorepComponents})
    scorep_enable("${allTargets}")
endif()

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(tests)
endif()
