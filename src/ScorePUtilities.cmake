# Copyright 2024 Eric Niklas Wolf
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

include("${CMAKE_CURRENT_LIST_DIR}/ScorePUtilities/analysis.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ScorePUtilities/properties.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ScorePUtilities/settings.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ScorePUtilities/targets.cmake")

function(_scorep_list_find_regex lst regex result)
    set(index 0)
    foreach(element ${lst})
        if(element MATCHES "${regex}")
            set("${result}" ${index} PARENT_SCOPE)
            return()
        endif()
        math(EXPR index "${index} + 1")
    endforeach()
    set("${result}" -1 PARENT_SCOPE)
endfunction()

# Infers Score-P arguments for instrumenting a specific language of a target.
function(scorep_infer_arguments target language arguments result)
    _scorep_arguments2settings("${arguments}" 100 ARGUMENT)
    _scorep_environment2settings("${language}" 1500 INFERRED)
    _scorep_merge_settings(ARGUMENT INFERRED ARGUMENT)
    _scorep_determine_link_closure("${target}" _scorep_all_visitor _scorep_all_visitor dependencies)
    foreach(dependency ${dependencies})
        _scorep_link_dependency2settings("${dependency}" "${language}" 1500 INFERRED)
        _scorep_merge_settings(ARGUMENT INFERRED ARGUMENT)
    endforeach()
    _scorep_settings2arguments(ARGUMENT arguments)
    set("${result}" "${arguments}" PARENT_SCOPE)
endfunction()


# Get components required to be present when finding Score-P based of the arguments and language of a target.
function(scorep_arguments2components arguments lang result)
    set(components "")
    foreach(argument ${arguments})
        if(argument MATCHES "^--thread=omp(:.+)?$")
            if(CMAKE_MATCH_1 STREQUAL ":opari2")
                list(APPEND components "OPARI2")
            elseif(CMAKE_MATCH_1 STREQUAL ":ompt")
                list(APPEND components "OMPT")
            endif()
            list(APPEND components "OMP_${lang}")
        elseif(argument STREQUAL "--thread=pthread")
            list(APPEND components PTHREAD)
        elseif(argument STREQUAL "--mpp=mpi")
            list(APPEND components MPP_mpi)
        elseif(argument STREQUAL "--mpp=shmem")
            list(APPEND components MPP_shmem)
        elseif(argument STREQUAL "--io=posix")
            list(APPEND components IO_posix)
        elseif(argument STREQUAL "--compiler")
            list(APPEND components COMPILER)
        elseif(argument STREQUAL "--cuda")
            list(APPEND components CUDA)
        elseif(argument STREQUAL "--openmp")
            list(APPEND components "OMP_${lang}")
        elseif(argument STREQUAL "--pdt")
            list(APPEND components PDT)
        elseif(argument STREQUAL "--opencl")
            list(APPEND components OPENCL)
        elseif(argument STREQUAL "--openacc")
            list(APPEND components OPENACC)
        elseif(argument STREQUAL "--memory")
            list(APPEND components MEMORY)
        elseif(argument STREQUAL "--kokkos")
            list(APPEND components KOKKOS)
        elseif(argument STREQUAL "--hip")
            list(APPEND components HIP)
        endif()
    endforeach()
    set("${result}" "${components}" PARENT_SCOPE)
endfunction()


# Get components required to be present when finding Score-P based on current CMake variables.
function(scorep_infer_components language result)
    set(detectedComponents "")
    if(language STREQUAL C)
        set(scorepLanguage "C99")
    elseif(language STREQUAL CXX)
        set(scorepLanguage "CXX11")
    elseif(language STREQUAL Fortran)
        set(scorepLanguage "Fortran")
    else()
        set("${result}" "${detectedComponents}" PARENT_SCOPE)
        return()
    endif()
    if(CMAKE_${language}_COMPILER)
        list(APPEND detectedComponents "COMPILER_${scorepLanguage}_${CMAKE_${language}_COMPILER}")
    endif()
    if(MPI_${language}_COMPILER)
        list(APPEND detectedComponents "MPI_COMPILER_${scorepLanguage}_${MPI_${language}_COMPILER}")
    endif()
    set("${result}" "${detectedComponents}" PARENT_SCOPE)
endfunction()


# Discovers targets in directories and stores them as a list in a variable.
function(scorep_discover_targets result)
    set(targets "")
    if("${ARGN}" STREQUAL "")
        set(directories "${CMAKE_CURRENT_SOURCE_DIR}")
    else()
        set(directories "${ARGN}")
    endif()
    foreach(directory ${directories})
        _scorep_get_all_targets("${directory}" directoryTargets)
        set(validTargets "")
        foreach(directoryTarget ${directoryTargets})
            get_target_property(type "${directoryTarget}" TYPE)
            if(type STREQUAL "INTERFACE_LIBRARY")
                continue()
            endif()
            get_target_property(imported "${directoryTarget}" IMPORTED)
            if((NOT imported STREQUAL "imported-NOTFOUND") AND imported)
                continue()
            endif()
            get_target_property(aliased "${directoryTarget}" ALIASED_TARGET)
            if((NOT aliased STREQUAL "aliased-NOTFOUND") AND aliased)
                continue()
            endif()
            list(APPEND validTargets "${directoryTarget}")
        endforeach()
        list(APPEND targets ${validTargets})
    endforeach()
    list(REMOVE_DUPLICATES targets)
    set("${result}" "${targets}" PARENT_SCOPE)
endfunction()


# Configures targets to be instrumented by Score-P.
function(scorep_instrument targets)
    cmake_parse_arguments(
        ARG
        "OVERRIDE;AUTO;OVERRIDE_VARIABLES"
        ""
        "LANGS;ARGUMENTS"
        ${ARGN}
    )
    if(NOT (DEFINED ScoreP_FOUND AND TARGET ScoreP::ScoreP))
        message(FATAL_ERROR "Score-P: called 'scorep_instrument' before finding ScoreP")
        return()
    endif()
    get_target_property(scorep ScoreP::ScoreP IMPORTED_LOCATION)

    if(ARG_AUTO)
        _scorep_arguments2settings("${ARG_ARGUMENTS}" 100 ARGUMENT)
    endif()

    foreach(target ${targets})
        if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_LANGUAGES_${target}")
            set(languages "${SCOREP_LANGUAGES_${target}}")
        else()
            set(languages ${ARG_LANGS})
        endif()
        if(ARG_AUTO)
            _scorep_determine_link_closure("${target}" _scorep_all_visitor _scorep_all_visitor dependencies)
        endif()
        foreach(lang ${languages})
            get_target_property(existingLauncher "${target}" ${lang}_COMPILER_LAUNCHER)
            if (NOT (ARG_OVERRIDE OR existingLauncher STREQUAL "existingLauncher-NOTFOUND"))
                message(
                    FATAL_ERROR
                    "Score-P: target ${target} has ${lang}_COMPILER_LAUNCHER already set to ${existingLauncher}"
                    "Please check that the target in not already instrumented by something or unset the property."
                )
            endif()
            get_target_property(existingLauncher "${target}" ${lang}_LINKER_LAUNCHER)
            if (NOT (ARG_OVERRIDE OR existingLauncher STREQUAL "existingLauncher-NOTFOUND"))
                message(
                    FATAL_ERROR
                    "Score-P: target ${target} has ${lang}_LINKER_LAUNCHER already set to ${existingLauncher}"
                    "Please check that the target in not already instrumented by something or unset the property."
                )
            endif()
            if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_${lang}_ARGUMENTS_${target}")
                set(arguments "${SCOREP_${lang}_ARGUMENTS_${target}}")
            else()
                set(arguments ${ARG_ARGUMENTS})
            endif()
            if(ARG_AUTO)
                _scorep_environment2settings("${lang}" 1500 INFERRED)
                _scorep_merge_settings(ARGUMENT INFERRED TARGET_ARGUMENT)
                foreach(dependency ${dependencies})
                    _scorep_link_dependency2settings("${dependency}" "${lang}" 1500 INFERRED)
                    _scorep_merge_settings(TARGET_ARGUMENT INFERRED TARGET_ARGUMENT)
                endforeach()
                _scorep_settings2arguments(TARGET_ARGUMENT targetLauncher)
                list(PREPEND targetLauncher "${scorep}")
            else()
                set(targetLauncher "${scorep}" ${arguments})
            endif()
            set_target_properties("${target}" PROPERTIES ${lang}_COMPILER_LAUNCHER "${targetLauncher}")
            set_target_properties("${target}" PROPERTIES ${lang}_LINKER_LAUNCHER "${targetLauncher}")
        endforeach()
    endforeach()
endfunction()


# Marks targets for the high-level interface.
function(scorep_mark mode targets)
    if(NOT (mode STREQUAL "HINT" OR mode STREQUAL "INSTRUMENT"))
        message(FATAL_ERROR "Score-P: called 'scorep_mark' with invalid mode: '${mode}'")
        return()
    endif()
    cmake_parse_arguments(
        ARG
        "AUTO"
        "PRIORITY"
        "LANGS;ARGUMENTS"
        ${ARGN}
    )
    if(NOT DEFINED ARG_PRIORITY)
        set(ARG_PRIORITY 100)
    elseif(ARG_PRIORITY STREQUAL "OPTIONAL")
        set(ARG_PRIORITY 1000)
    elseif(ARG_PRIORITY STREQUAL "DEFAULT")
        set(ARG_PRIORITY 100)
    elseif(ARG_PRIORITY STREQUAL "FORCE")
        set(ARG_PRIORITY 0)
    elseif(ARG_PRIORITY MATCHES "^[0-9]+$")
    else()
        message(FATAL_ERROR "Score-P: called 'scorep_mark' with invalid priority: '${ARG_PRIORITY}'")
        return()
    endif()
    _scorep_arguments2settings("${ARG_ARGUMENTS}" "${ARG_PRIORITY}" ARGUMENT)

    foreach(target ${targets})
        if(ARG_AUTO)
            _scorep_determine_link_closure("${target}" _scorep_all_visitor _scorep_all_visitor dependencies)
        endif()
        foreach(lang ${ARG_LANGS})
            if(ARG_AUTO)
                _scorep_environment2settings("${lang}" 1500 INFERRED)
                _scorep_merge_settings(ARGUMENT INFERRED TARGET_ARGUMENT)
                foreach(dependency ${dependencies})
                    _scorep_link_dependency2settings("${dependency}" "${lang}" 1500 INFERRED)
                    _scorep_merge_settings(TARGET_ARGUMENT INFERRED TARGET_ARGUMENT)
                endforeach()
                _scorep_settings2properties(TARGET_ARGUMENT "${lang}" "${target}")
            else()
                _scorep_settings2properties(ARGUMENT "${lang}" "${target}")
            endif()
        endforeach()
        if(mode STREQUAL "INSTRUMENT")
            get_target_property(imported "${target}" IMPORTED)
            get_target_property(aliased "${target}" ALIASED_TARGET)
            if(imported)
                message(WARNING "Score-P: imported target '${target}' can not be instrumented")
            elseif(aliased)
                message(WARNING "Score-P: alias target '${target}' can not be instrumented")
            else()
                set_property(TARGET "${target}" APPEND PROPERTY SCOREP_LANGUAGES ${ARG_LANGS})
            endif()
        endif()
    endforeach()
endfunction()


# Determines which and how targets marked by `scorep_mark` need to be instrumented.
function(scorep_determine_instrumentations targets)
    cmake_parse_arguments(
        ARG
        ""
        "COMPONENTS_VAR"
        ""
        ${ARGN}
    )
    set(components "")
    set(UNIONFIND_ELEMENTS "")

    set(standaloneTargets "")
    foreach(target IN LISTS targets)
        get_target_property(type "${target}" TYPE)
        if(type STREQUAL "EXECUTABLE" OR type STREQUAL "SHARED_LIBRARY" OR type STREQUAL "MODULE_LIBRARY")
            list(APPEND standaloneTargets "${target}")
        endif()
    endforeach()

    # calculate all local sets
    _scorep_calculate_sets("${standaloneTargets}" _scorep_local_dependencies TMP sets)
    # make sure the stand-alone target of the local set is instrumented with the required languages
    foreach(target IN LISTS sets)
        set_target_properties(
            "${target}"
            PROPERTIES SCOREP_LANGUAGES
            "${TMP_${target}_LANGUAGES}"
        )
    endforeach()
    _scorep_merge_sets(UNIONFIND sets TMP LOCALSET localSets)

    # calculate all global sets
    _scorep_calculate_sets("${standaloneTargets}" _scorep_global_dependencies TMP sets)
    _scorep_merge_sets(UNIONFIND sets TMP GLOBALSET globalSets)

    # calculate global set settings
    foreach(globalSet IN LISTS globalSets)
        foreach(setting IN LISTS _SCOREP_FLAG_SETTINGS _SCOREP_CHOICE_SETTINGS _SCOREP_UNION_SETTINGS)
            set("GLOBAL_${globalSet}_${setting}" "")
        endforeach()
        foreach(language IN LISTS "GLOBALSET_${globalSet}_LANGUAGES")
            foreach(target IN LISTS "GLOBALSET_${globalSet}_ELEMENTS")
                _scorep_properties2settings(DEPENDENCY "${language}" "${target}")
                foreach(setting IN LISTS _SCOREP_STANDALONE_FLAG_SETTINGS _SCOREP_STANDALONE_CHOICE_SETTINGS _SCOREP_STANDALONE_UNION_SETTINGS)
                    set("DEPENDENCY_${setting}" "")
                endforeach()
                _scorep_merge_settings("GLOBAL_${globalSet}" DEPENDENCY "GLOBAL_${globalSet}")
            endforeach()   
        endforeach()
    endforeach()

    # calculate local set settings and instrument
    foreach(localSet IN LISTS localSets)
        # find the global set of this local set
        _scorep_unionfind_find(UNIONFIND "${localSet}" found)

        # calculate settings for all languages
        foreach(setting IN LISTS _SCOREP_FLAG_SETTINGS _SCOREP_CHOICE_SETTINGS _SCOREP_UNION_SETTINGS)
            # inherit global settings
            set("LOCAL_${setting}" "${GLOBAL_${found}_${setting}}")
        endforeach()
        foreach(language IN LISTS "LOCALSET_${localSet}_LANGUAGES")
            foreach(dependency IN LISTS "LOCALSET_${localSet}_ELEMENTS")
                _scorep_properties2settings(DEPENDENCY "${language}" "${dependency}")
                # notstandalone settings where already merged by the global settings
                foreach(setting IN LISTS _SCOREP_NOTSTANDALONE_FLAG_SETTINGS _SCOREP_NOTSTANDALONE_CHOICE_SETTINGS _SCOREP_NOTSTANDALONE_UNION_SETTINGS)
                    set("DEPENDENCY_${setting}" "")
                endforeach()
                _scorep_merge_settings(LOCAL DEPENDENCY LOCAL)
            endforeach()
        endforeach()

        # generate Score-P arguments
        _scorep_settings2arguments(LOCAL arguments)
        if(ARG_COMPONENTS_VAR)
            foreach(language IN LISTS "LOCALSET_${localSet}_LANGUAGES")
                scorep_arguments2components("${arguments}" "${language}" localComponents)
                list(APPEND components ${localComponents})
                list(REMOVE_DUPLICATES components)
            endforeach()
        endif()

        # instrument local set
        foreach(target IN LISTS "LOCALSET_${localSet}_ELEMENTS")
            get_target_property(targetLanguages "${target}" SCOREP_LANGUAGES)
            if(NOT targetLanguages STREQUAL "targetLanguages-NOTFOUND")
                foreach(language IN LISTS targetLanguages)
                    get_target_property(targetArguments "${target}" "SCOREP_${language}_ARGUMENTS")
                    if(targetArguments STREQUAL "targetArguments-NOTFOUND")
                        set_target_properties(
                            "${target}"
                            PROPERTIES "SCOREP_${language}_ARGUMENTS"
                            "${arguments}"
                        )
                    elseif(NOT targetArguments STREQUAL "${arguments}")
                        message(FATAL_ERROR "Score-P: target ${target} has SCOREP_${language}_ARGUMENTS already set to '${targetArguments}' instead of '${arguments}'")
                    endif()
                endforeach()
            endif()
        endforeach()
    endforeach()

    if(ARG_COMPONENTS_VAR)
        set("${ARG_COMPONENTS_VAR}" "${components}" PARENT_SCOPE)
    endif()
endfunction()


# Instruments targets marked by `scorep_mark` using `scorep_instrument` based on the `SCOREP_<LANG>_ARGUMENTS` target property.
function(scorep_enable targets)
    cmake_parse_arguments(
        ARG
        "OVERRIDE;OVERRIDE_VARIABLES"
        ""
        ""
        ${ARGN}
    )

    foreach(target ${targets})
        if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_LANGUAGES_${target}")
            set(languages "${SCOREP_LANGUAGES_${target}}")
        else()
            get_target_property(languages "${target}" SCOREP_LANGUAGES)
            if(languages STREQUAL "languages-NOTFOUND")
                continue()
            endif()
        endif()
        foreach(lang ${languages})
            if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_${lang}_ARGUMENTS_${target}")
                set(arguments "${SCOREP_${lang}_ARGUMENTS_${target}}")
            else()
                get_target_property(arguments "${target}" SCOREP_${lang}_ARGUMENTS)
                if(arguments STREQUAL "arguments-NOTFOUND")
                    continue()
                endif()
            endif()
            if(ARG_OVERRIDE)
                scorep_instrument("${target}" LANGS ${lang} ARGUMENTS ${arguments} OVERRIDE_VARIABLES OVERRIDE)
            else()
                scorep_instrument("${target}" LANGS ${lang} ARGUMENTS ${arguments} OVERRIDE_VARIABLES)
            endif()
        endforeach()
    endforeach()
endfunction()
