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


set(_SCOREP_STANDALONE_FLAG_SETTINGS compiler cuda online-access pomp pdt preprocess user opencl openacc memory kokkos)
set(_SCOREP_NOTSTANDALONE_FLAG_SETTINGS openmp)
set(_SCOREP_FLAG_SETTINGS ${_SCOREP_STANDALONE_FLAG_SETTINGS} ${_SCOREP_NOTSTANDALONE_FLAG_SETTINGS})
set(_SCOREP_STANDALONE_CHOICE_SETTINGS mutex)
set(_SCOREP_NOTSTANDALONE_CHOICE_SETTINGS thread mpp)
set(_SCOREP_CHOICE_SETTINGS ${_SCOREP_STANDALONE_CHOICE_SETTINGS} ${_SCOREP_NOTSTANDALONE_CHOICE_SETTINGS})
set(_SCOREP_STANDALONE_UNION_SETTINGS other)
set(_SCOREP_NOTSTANDALONE_UNION_SETTINGS io)
set(_SCOREP_UNION_SETTINGS ${_SCOREP_STANDALONE_UNION_SETTINGS} ${_SCOREP_NOTSTANDALONE_UNION_SETTINGS})

# properties can only be defined in project mode
get_property(__role GLOBAL PROPERTY CMAKE_ROLE)
if(__role STREQUAL "PROJECT")
    define_property(
        TARGET PROPERTY "SCOREP_LANGUAGES"
        BRIEF_DOCS "Target property which when defined contains all languages to be instrumented when calling `scorep_enable`."
    )
    define_property(
        TARGET PROPERTY "SCOREP_AUTO_LANGUAGES"
        BRIEF_DOCS "Target property which contains a list of languages for which automatic detection of Score-P arguments is to be performed."
    )
    foreach(language C CXX Fortran CUDA HIP)
        define_property(
            TARGET PROPERTY "SCOREP_${language}_ARGUMENTS"
            BRIEF_DOCS "Target property which when defined contains the determined arguments for Score-P for language '${language}'."
        )
        foreach(setting IN LISTS _SCOREP_FLAG_SETTINGS _SCOREP_CHOICE_SETTINGS _SCOREP_UNION_SETTINGS)
            define_property(
                TARGET PROPERTY "SCOREP_${language}_SETTING_${setting}"
                BRIEF_DOCS "Target property which contains the value of Score-P setting '${setting}' when instrumenting language '${language}'."
            )
        endforeach()
    endforeach()
endif()
unset(__role)
