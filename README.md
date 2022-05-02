# MO2 CMake Common

This repository contains CMake macro and functions that are used in most MO2
repository to build uibase, modorganizer itself and plugins (C++/Python).

## Getting Started

To get started, simply include the `mo2.cmake` file in your project:

```cmake
# this can safely be included multiple time
include(path_to_cmake_common/mo2.cmake)
```

This will set some (not too intrusive) variables and define many useful functions,
all prefixed with `mo2_`.

The basic MO2 plugin/executable CMake will then look like this:

```cmake
# this is for a C++ plugin
add_library(my_plugin SHARED)

# configure the plugin - this will also set the sources of the plugin
# based on the file in the current directory (and subdirectory)
mo2_configure_plugin(my_plugin)

# install the target to MO2 installation path, typically in the
# plugins/ folder
mo2_install_target(my_plugin)
```

## Configuring

The main entry-points are the the configure functions:

- C++
  - `mo2_configure_target` - this is the "base" configuration,
    which should not be used most of the time (this one is called by
    other functions),
  - `mo2_configure_uibase` - specific for uibase, should not be used
    elsewhere,
  - `mo2_configure_plugin` - configuration for a C++ plugin,
  - `mo2_configure_library` - configuration for static or shared libraries,
  - `mo2_configure_executable` - configuration for executables, including the main
    MO2 executable,
  - `mo2_configure_tests` - configuration for tests.
- Python
  - `mo2_configure_python`.

The function are documented so you can look at the documentation to see what arguments
are available.

### Dependencies

You can add dependencies to the target by using the standard `target_link_libraries`,
but this might be difficult when looking for MO2 dependencies, such as other libraries
or Qt.

The `mo2_configure_XXX` accept `PRIVATE_DEPENDS` and `PUBLIC_DEPENDS` parameters that
can be used to add dependencies to the target in an easier way.
These parameters accept 3 types of dependencies:

- Qt dependencies, that should be specified as `Qt::COMPONENTS`, e.g., `Qt::Core` or
  `Qt::Widgets`. Note that the `Qt::` is version-independent, MO2 will add the proper
  version for you.
- Boost dependencies - For header only libraries, you can simply pass `boost`, for
  non-header only libraries, you can pass `boost::COMPONENT`, e.g., `boost::threads`.
- MO2 dependencies - Those are either components available via the MO2 build system,
  such as `zlib` or `libbsarch`, or other MO2 components such as `game_gamebryo`.

## Installing

For C++ plugin, you need to call `mo2_install_target` to install the plugins or
executable in MO2 installation directory.
Where the target should be installed is defined in the `mo2_configure_XXX` function
(which should be called before `mo2_install_target`).

Installing Python plugins does not require extra call apart from `mo2_configure_python`.

## Examples

All MO2 repositories use these functions, so you can look at any repository to get
details on how to use them.
Here are entry points for the various type of plugins:

- [`game_skyrimse`](https://github.com/ModOrganizer2/modorganizer-game_skyrimSE/)
  for a plugin that depends on a static library built by MO2.
- [`game_gamebryo`](https://github.com/ModOrganizer2/modorganizer-game_gamebryo/)
  for a static library example.
- [`installer_wizard`](https://github.com/ModOrganizer2/modorganizer-installer_wizard)
  for a Python plugin (module).
- [`fnistool`](https://github.com/ModOrganizer2/modorganizer-fnistool/) for a Python
  plugin (simple file).
