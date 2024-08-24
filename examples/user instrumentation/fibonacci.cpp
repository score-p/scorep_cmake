#include <iostream>
#include <vector>
#include <boost/program_options.hpp>
#ifdef SCOREP_USER_ENABLE
#include <scorep/SCOREP_User.h>
#endif

namespace options = boost::program_options;

static unsigned long fibonacci(unsigned long element) {
    #ifdef SCOREP_USER_ENABLE
    SCOREP_USER_REGION("fibonacci function", SCOREP_USER_REGION_TYPE_FUNCTION)
    #endif
    unsigned long a = 0;
    unsigned long b = 1;
    while (element > 0) {
        auto tmp = a + b;
        a = b;
        b = tmp;
        element--;
    }
    return a;
}

static void calculate_elements(const unsigned int start, const unsigned int step, std::vector<unsigned long>* buffer) {
    #ifdef SCOREP_USER_ENABLE
    SCOREP_USER_REGION("calculate_elements function", SCOREP_USER_REGION_TYPE_FUNCTION)
    #endif
    for (unsigned int index = 0; index < buffer->size(); index++) {
        (*buffer)[index] = fibonacci(start + index * step);
    }
}

static void print_elements(const unsigned int start, const unsigned int step, std::vector<unsigned long>* buffer) {
    std::cout << "Calculated elements:\n";
    auto element = start;
    for (auto value: *buffer) {
        std::cout << element << ": " << value << "\n";
        element += step;
    }
}

int main(int argc, char** argv) {
    unsigned int start, step, count;

    options::options_description desc("Allowed options");
    desc.add_options()
        ("help,h", "display help message")
        ("start", options::wvalue<unsigned int>(&start)->required(), "starting index of the fibonacci sequence")
        ("step", options::value<unsigned int>(&step)->required(), "step size between the calculated values")
        ("count", options::value<unsigned int>(&count)->required(), "amount of elements to be calculated");
    options::positional_options_description positionals;
    positionals
        .add("start", 1)
        .add("step", 1)
        .add("count", 1);

    options::variables_map arguments;

    try {
        auto parsed = options::command_line_parser(argc, argv).options(desc).positional(positionals).style(options::command_line_style::unix_style).run();
        options::store(parsed, arguments);
        if (arguments.count("help")) {
            std::cout << "Example which calculates elements of the fibonacci sequence" << "\n\n";
            std::cout << "Usage: fibonacci [OPTIONS] [start step count]" << "\n";
            std::cout << desc << "\n";
            return 0;
        }
        options::notify(arguments);
    } catch (options::error& e) {
        std::cerr << "Error while parsing arguments: " << e.what() << "\n";
        return 1;
    }

    std::vector<unsigned long> buffer(count);
    printf("Calculating elements with start: %u, step: %u and count: %u\n", start, step, count);
    calculate_elements(start, step, &buffer);
    print_elements(start, step, &buffer);
    return 0;
}