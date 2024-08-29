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


# Add a not already existing element as a singleton set.
macro(_scorep_unionfind_makeset prefix element)
    set("${prefix}_${element}_PARENT" "${element}")
    set("${prefix}_${element}_SIZE" 1)
    list(APPEND "${prefix}_ELEMENTS" "${element}")
endmacro()

# Find the root element of the set of an element if it exists.
function(_scorep_unionfind_find prefix element result)
    if(NOT DEFINED "${prefix}_${element}_PARENT")
        set("${result}" "${result}-NOTFOUND" PARENT_SCOPE)
        return()
    endif()
    set(root "${${prefix}_${element}_PARENT}")
    while(1)
        set(parent "${${prefix}_${root}_PARENT}")
        if(parent STREQUAL root)
            break()
        else()
            # use path splitting
            set("${prefix}_${root}_PARENT" "${${prefix}_${parent}_PARENT}" PARENT_SCOPE)
            set(root "${parent}")
        endif()
    endwhile()
    set("${result}" "${root}" PARENT_SCOPE)
endfunction()

# Merge two sets by their root elements.
function(_scorep_unionfind_union prefix root1 root2)
    if(NOT root1 STREQUAL root2)
        # use union by size
        if("${prefix}_${root1}_SIZE" LESS "${prefix}_${root2}_SIZE")
            set(tmp "${root1}")
            set(root1 "${root2}")
            set(root2 "${tmp}")
        endif()
        set("${prefix}_${root2}_PARENT" "${root1}" PARENT_SCOPE)
        math(EXPR newSize "${${prefix}_${root1}_SIZE} + ${${prefix}_${root2}_SIZE}")
        set("${prefix}_${root1}_SIZE" "${newSize}" PARENT_SCOPE)
    endif()
endfunction()

# Internal function for calculating initial sets of targets.
function(_scorep_calculate_sets targets dependencies prefix result)
    set(sets "")
    foreach(target IN LISTS targets)
        set(elements "")
        set(languages "")
        cmake_language(CALL "${dependencies}" "${target}" set)
        foreach(element IN LISTS set ITEMS "${target}")
            if(TARGET "${element}")
                list(APPEND elements "${element}")
                get_target_property(targetLanguages "${element}" SCOREP_LANGUAGES)
                if(NOT targetLanguages STREQUAL "targetLanguages-NOTFOUND")
                    list(APPEND languages ${targetLanguages})
                endif()
            endif()
        endforeach()
        if(NOT languages STREQUAL "")
            list(APPEND sets "${target}")
            list(REMOVE_DUPLICATES languages)
            set("${prefix}_${target}_ELEMENTS" "${elements}" PARENT_SCOPE)
            set("${prefix}_${target}_LANGUAGES" "${languages}" PARENT_SCOPE)
        endif()
    endforeach()
    set("${result}" "${sets}" PARENT_SCOPE)
endfunction()

function(_scorep_local_dependencies target result)
    _scorep_determine_link_closure("${target}" _scorep_not_standalone_visitor _scorep_all_visitor dependencies)
    set("${result}" "${dependencies}" PARENT_SCOPE)
endfunction()

function(_scorep_global_dependencies target result)
    _scorep_determine_link_closure("${target}" _scorep_all_visitor _scorep_all_visitor dependencies)
    set("${result}" "${dependencies}" PARENT_SCOPE)
endfunction()

# Merge sets base don shared instrumented elements.
macro(_scorep_merge_sets unionfindPrefix setsVar prefixIn prefixOut result)
    foreach(set IN LISTS "${setsVar}")
        _scorep_unionfind_find("${unionfindPrefix}" "${set}" setFound)
        if(setFound STREQUAL "setFound-NOTFOUND")
            _scorep_unionfind_makeset("${unionfindPrefix}" "${set}")
            set(setFound "${set}")
        endif()
        foreach(element IN LISTS "${prefixIn}_${set}_ELEMENTS")
            get_target_property(targetLanguages "${element}" SCOREP_LANGUAGES)
            if(NOT (targetLanguages STREQUAL "targetLanguages-NOTFOUND" OR targetLanguages STREQUAL ""))
                _scorep_unionfind_find("${unionfindPrefix}" "${element}" elementFound)
                if(elementFound STREQUAL "elementFound-NOTFOUND")
                    _scorep_unionfind_makeset("${unionfindPrefix}" "${element}")
                    set(elementFound "${element}")
                endif()
                _scorep_unionfind_union("${unionfindPrefix}" "${setFound}" "${elementFound}")
            endif()
        endforeach()
    endforeach()
    
    set("${result}" "")
    foreach(set IN LISTS "${setsVar}")
        _scorep_unionfind_find("${unionfindPrefix}" "${set}" found)
        list(APPEND "${result}" "${found}")
        list(APPEND "${prefixOut}_${found}_ELEMENTS" ${${prefixIn}_${set}_ELEMENTS})
        list(APPEND "${prefixOut}_${found}_LANGUAGES" ${${prefixIn}_${set}_LANGUAGES})
    endforeach()
    list(REMOVE_DUPLICATES "${result}")
    foreach(set IN LISTS "${result}")
        list(REMOVE_DUPLICATES "${prefixOut}_${set}_ELEMENTS")
        list(REMOVE_DUPLICATES "${prefixOut}_${set}_LANGUAGES")
    endforeach()
endmacro()
