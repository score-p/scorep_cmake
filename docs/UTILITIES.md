# ScorePUtilities Module

This module implements two ways of instrumenting targets with Score-P.

The low-level interface allows you to have direct control over how Score-P is executed
at the cost of convenience.

The high-level interface allows infering Score-P arguments and detecting conflicts
at the cost of sometimes needing a little help.

## Low-level interface

### Functions

#### scorep_instrument(targets)

Configures targets to be instrumented by Score-P and supports the following keywords:

 - `OVERRIDE`, an option that when enabled allows overwriting existing `<LANG>_COMPILER_LAUNCHER` and `<LANG>_LINKER_LAUNCHER` properties

 - `LANGS`, a multi-value keyword which lists the names of the languages to instrument

 - `ARGUMENTS`, a multi-value keyword which lists the commandline arguments to Score-P

 - `AUTO`, an option which enables automatic detection of Score-P arguments using `scorep_infer_arguments`

 - `OVERRIDE_VARIABLES`, an option which disables processing of `SCOREP_LANGUAGES_<TARGET>` and `SCOREP_<LANG>_ARGUMENTS_<TARGET>`

**`find_package(ScoreP ...)` has to be executed successfully before this function can be used!**

### Properties

 - `SCOREP_LANGUAGES_<TARGET>`, a cache variable which may override the `SCOREP_LANGUAGES` property of a target.

 - `SCOREP_<LANG>_ARGUMENTS_<TARGET>`, a cache variable which may override the `SCOREP_<LANG>_ARGUMENTS` property of a target.

The cache variables are intended to be set by users who wish to override which and how targets are instrumented when calling `scorep_enable`.


## High-level interface

### Functions

#### scorep_mark(mode targets)

Marks targets for the high-level interface:

 - mode `HINT` sets setting properties on the targets but does not mark them to be instrumented

 - mode `INSTRUMENT` additionally marks the targets to be instrumented

The function supports the following keywords:

 - `LANGS`, a multi-value keyword which lists the names of the languages to mark

 - `ARGUMENTS`, a multi-value keyword which lists the commandline arguments to Score-P

 - `PRIORITY`, a single-value keyword which takes the priority of the settings set by this call

 - `AUTO`, an option which enables automatic detection of Score-P arguments using `scorep_infer_arguments`
   with priority 1500 when calling `scorep_determine_instrumentations`

The function does nothing by itself besides setting the `SCOREP_LANGUAGES`, `SCOREP_<LANG>_SETTING_<SETTING>`
and `SCOREP_AUTO_LANGUAGES` properties.

The priority passed to `PRIORITY` supports in addition to numerical values:

 - `OPTIONAL`, alias for 1000

 - `DEFAULT`, alias for 100

 - `FORCE`, alias for 0

#### scorep_determine_instrumentations(targets)

Determines which and how targets marked by `scorep_mark` need to be instrumented.

The functions supports the following keywords:

 - `COMPONENTS_VAR`, a single-value keyword which takes the variable in which the required components for the find module are stored.

The passed targets are filtered so that only targets which can be instrumented individually
by Score-P (shared and module libraries and executables) remain.

For each of these targets two sets of dependencies are calculated.

The first (local) set of a target includes all transitive link dependencies excluding dependencies
which are linked to through targets which can be instrumented individually by Score-P.

Since the top level and all Score-P enabled targets of the local set have to use the same Score-P settings
they are merged for each set and the top level target instrumented when any dependency is instrumented by Score-P.

Since some settings like `thread`, `mpp` and `io` have to be the same across all dependencies of a target they
are merged in another set containing them called the global set.

Since a target which should be instrumented by Score-P can only be instrumented
with one value for each setting they can only be in one local and global set.

In the case a instrumented target is contained in multiple local or global sets they are
merged to prevent multiple settings from being choosen.

When merging of some settings fails a CMake error is generated when calculating Score-P arguments.

The Score-P arguments determined for each Score-P enabled target are stored in the `SCOREP_<LANG>_ARGUMENTS` target property.

**Since generator expressions can not be evaluated dependencies specified by them are ignored!**

#### scorep_enable(targets)

Instruments targets marked by `scorep_mark` using `scorep_instrument` based on the `SCOREP_<LANG>_ARGUMENTS` target property.

The function supports the following keywords:

 - `OVERRIDE`, an option that when enabled allows overwriting existing `<LANG>_COMPILER_LAUNCHER` and `<LANG>_LINKER_LAUNCHER` properties

 - `OVERRIDE_VARIABLES`, an option which disables processing of `SCOREP_LANGUAGES_<TARGET>` and `SCOREP_<LANG>_ARGUMENTS_<TARGET>`

**`find_package(ScoreP ...)` has to be executed successfully before this function can be used!**

### Properties

 - `SCOREP_LANGUAGES`, a target property which when defined contains all languages to be instrumented when calling `scorep_enable`.

 - `SCOREP_AUTO_LANGUAGES`, a target property which contains a list of languages for which automatic detection of Score-P arguments is to be performed

 - `SCOREP_<LANG>_ARGUMENTS`, a target property which when defined contains the determined arguments for Score-P

 - `SCOREP_<LANG>_SETTING_<SETTING>`, a target property which contains the value of a certain Score-P setting when instrumenting language LANG.

#### Setting properties

All setting properties contain their value prefixed by `<PRIORITY>;`,
where the priority is a non-negative number specifying the priority
of this setting when being merged with other settings.

If there are multiple values available for a setting the values with
the highest priority (smallest number) are selected.

If there are still multiple values remaining they are attempted to be merged,
which causes a CMake error if not possible.

As an implementation detail, settings with a value of `CONFLICT;<PRIORITY>;<MESSAGE>` are converted
into CMake errors when not overridden before being converted into arguments or target properties.

This means that when merging the settings of multiple dependencies conflict errors are delayed
until argument or property generation in hope of another setting with a higher priority
overriding the conflict.

##### Choice settings

For the settings `thread`, `mpp` and `mutex` the value of the property `SCOREP_<LANG>_SETTING_<SETTING>`
has the form of `<PRIORITY>;<PARADIGM>[;<VARIANT>]`:

 - `PRIORITY` is the priority of this value

 - `PARADIGM` is the choosen instrumentation paradigm

 - `VARIANT` is an option variant of the selected paradigm

Merging of two values (as lists `PARADIGM;VARIANT`) is possible when one is a prefix of the other,
in which case the longer list is used as the choosen value.

Example: merging `omp;ompt` with `omp` succeeds, while merging with `pthread` or `none` fails.

##### Flag settings

For the settings `compiler`, `cuda`, `online-access`, `pomp`, `openmp`, `pdt`, `preprocess`,
`user`, `opencl`, `openacc`, `kokkos` and `memory` the value of the property `SCOREP_<LANG>_SETTING_<SETTING>`
has the form of `<PRIORITY>;STATUS[;<SEPERATOR>;<PAYLOAD>]`:

 - `PRIORITY` is the priority of this value

 - `STATUS`, is the choice whether this setting is enabled or not

 - `SEPERATOR`, is an optional value used for seperating the flag and its payload

 - `PAYLOAD`, is an optional value associated with this setting when enabled

Merging of two values (as lists `STATUS;PAYLOAD`) is possible when one is a prefix of the other,
in which case the longer list is used as the choosen value.

##### Union settings

For the settings `io` and `other` the value of the property `SCOREP_<LANG>_SETTING_<SETTING>` has the form of `<PRIORITY>;VALUE`:

 - `PRIORITY` is the priority of this value

 - `VALUE`, is a list of values for this setting.

Merging two values (as lists of values) is always possible and results in concatenating the value lists.

The values of the `io` setting are given to `--io=` while the values of `other` are given directly to Score-P
as command line arguments.


## Utility functions

These function work independently of the low- or high-level interfaces and can be used with both.

### Functions

#### scorep_infer_arguments(target language arguments outVar)

Infers Score-P arguments for instrumenting a specific language of a target and merging them with existing arguments.

The result will be stored in the variable name contained in `outVar` as a list containing the new arguments.

To handle conflicts between inferred arguments override them with your own.

For more information on argument autodetection see [AUTODETECT.md](AUTODETECT.md#Arguments).

#### scorep_arguments2components(arguments language outVar)

Get components required to be present when finding Score-P based of the arguments and language of a target.

The result will be stored in the variable name contained in `outVar` as a list of components.

For more information on component autodetection see [AUTODETECT.md](AUTODETECT.md#Components).

#### scorep_infer_components(language outVar)

Get components required to be present when finding Score-P based on current CMake variables.

The result will be stored in the variable name contained in `outVar` as a list of components.

For more information on component autodetection see [AUTODETECT.md](AUTODETECT.md#Components).

#### scorep_discover_targets(outVar [directory ...])

Discovers targets in directories and stores them as a list in a variable named by `outVar`.

Targets which can not be instrumented by Score-P are automatically skipped.

The function defaults to the current directory if no directories or targets are passed.
