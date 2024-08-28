execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env SCOREP_CUDA_ENABLE=yes
    "${FIBONACCI_EXECUTABLE}" --start 0 --step 1 --count 10
    RESULT_VARIABLE result
)

if(NOT result EQUAL 0)
    message(FATAL_ERROR "fibinacci process failed")
endif()
file(GLOB files "./scorep-*")
if(files STREQUAL "")
    message(FATAL_ERROR "fibinacci process generated no Score-P results")
endif()
