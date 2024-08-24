execute_process(
    COMMAND "${FIBONACCI_EXECUTABLE}" --start 0 --step 1 --count 10
    RESULT_VARIABLE result
)

if(NOT result EQUAL 0)
    message(FATAL_ERROR "fibinacci process failed")
endif()
file(GLOB files "./scorep-*")
if(NOT files STREQUAL "")
    message(FATAL_ERROR "fibinacci process generated Score-P results: ${files}")
endif()
