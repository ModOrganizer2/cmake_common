cmake_minimum_required(VERSION 3.16)

if (POLICY CMP0144)
    cmake_policy(SET CMP0144 NEW)
endif()

include(FetchContent)
include(${CMAKE_CURRENT_LIST_DIR}/mo2_utils.cmake)

#! mo2_add_dependencies : add dependencies to the given target
#
# the name of the dependencies should be:
# - valid mo2 "libraries", as per mo2_find_libraries,
# - boost (for header-only Boost libraries) or "boost::XXX" for specific Boost
#   components
# - or Qt::XXX for Qt components
#
function(mo2_add_dependencies TARGET PRIVATE_OR_PUBLIC)

	# remove everything boost related
	set(standard_deps ${ARGN})
	list(FILTER standard_deps EXCLUDE REGEX "^boost.*")
	list(FILTER standard_deps EXCLUDE REGEX "^Qt::.*")

	# keep everything boost related
	set(boost_deps ${ARGN})
	list(FILTER boost_deps INCLUDE REGEX "^boost.*")

	# keep everything Qt related
	set(qt_deps ${ARGN})
	list(FILTER qt_deps INCLUDE REGEX "^Qt::.*")

	message(DEBUG "deps: standards[ ${standard_deps} ], boost_deps[ ${boost_deps} ], qt_deps[ ${qt_deps} ]")

	# handle "standard" dependencies
	mo2_find_libraries(${standard_deps})
	list(TRANSFORM standard_deps REPLACE "^(.+)$" "mo2::\\1")
	message(DEBUG "standard: ${standard_deps}")
	target_link_libraries(${TARGET} ${PRIVATE_OR_PUBLIC} ${standard_deps})

	# handle Qt dependencies
	if (qt_deps)
		# remove Qt:: for find_package
		list(TRANSFORM qt_deps REPLACE "Qt::" "")
		find_package(Qt${QT_MAJOR_VERSION} COMPONENTS ${qt_deps} REQUIRED)

		# add QtX:: for target ink
		list(TRANSFORM qt_deps REPLACE "^(.+)$" "Qt${QT_MAJOR_VERSION}::\\1")
		target_link_libraries(${TARGET} ${PRIVATE_OR_PUBLIC} ${qt_deps})
	endif()

	# handle boost dependencies
	if (boost_deps)
		find_package(Boost REQUIRED)
		target_include_directories(
			${TARGET} ${PRIVATE_OR_PUBLIC} ${Boost_INCLUDE_DIRS})

		list(TRANSFORM boost_deps REPLACE "boost(::)?" "")
		list(FILTER boost_deps EXCLUDE REGEX "^$")
		message(DEBUG "boost: ${boost_deps}")

        if (boost_deps)
    		find_package(Boost COMPONENTS ${boost_deps} REQUIRED)
	    	message(DEBUG "boost: ${Boost_LIBRARIES}")
		    target_link_libraries(${TARGET} ${PRIVATE_OR_PUBLIC} ${Boost_LIBRARIES})
        endif()
	endif()
endfunction()

#! mo2_find_uibase : find and create a mo2::uibase target
#
# if a 'uibase' target already exists, makes an alias as 'mo2::uibase', otherwise
# creates an imported target
#
function(mo2_find_uibase)

    # target was already created
    if (TARGET mo2-uibase)
        return()
    endif()

    # if the uibase target exists, we use it
    if (TARGET uibase)
        add_library(mo2-uibase ALIAS uibase)
        add_library(mo2::uibase ALIAS uibase)
    else()

        if (NOT DEFINED MO2_UIBASE_INCLUDE)
            set(MO2_UIBASE_INCLUDE ${MO2_UIBASE_PATH}/src)
        endif()


        add_library(mo2-uibase IMPORTED SHARED)
        set_target_properties(mo2-uibase PROPERTIES
            IMPORTED_IMPLIB ${MO2_INSTALL_LIBS_PATH}/uibase.lib
            IMPORTED_LOCATION ${MO2_INSTALL_PATH}/bin/uibase.dll)
        mo2_add_dependencies(mo2-uibase
            INTERFACE Qt::Widgets Qt::Network Qt::QuickWidgets)
        target_include_directories(mo2-uibase
            INTERFACE ${MO2_UIBASE_INCLUDE} ${MO2_UIBASE_INCLUDE}/game_features)
        add_library(mo2::uibase ALIAS mo2-uibase)
    endif()

endfunction()

#! mo2_find_corelib : find a static core library, e.g., bsatk or esptk, and create
# an appropriate target
#
function(mo2_find_corelib LIBRARY)
    cmake_parse_arguments(MO2 "" "" "DEPENDS" ${ARGN})

    mo2_set_if_not_defined(MO2_DEPENDS "")

    # target was already created
    if (TARGET mo2-${LIBRARY})
        return()
    endif()

    # if the target exists, we use it
    if (TARGET ${LIBRARY})
        message(STATUS "Found existing ${LIBRARY} target, using it.")

        add_library(mo2-${LIBRARY} ALIAS ${LIBRARY})
        add_library(mo2::${LIBRARY} ALIAS ${LIBRARY})
    else()
        message(STATUS "Existing ${LIBRARY} target not found, creating it.")

        add_library(mo2-${LIBRARY} IMPORTED STATIC)
        set_target_properties(mo2-${LIBRARY} PROPERTIES
            IMPORTED_LOCATION ${MO2_INSTALL_LIBS_PATH}/${LIBRARY}.lib)
        target_include_directories(mo2-${LIBRARY}
            INTERFACE ${MO2_SUPER_PATH}/${LIBRARY}/src)

        if (MO2_DEPENDS)
            mo2_add_dependencies(mo2-${LIBRARY} INTERFACE ${MO2_DEPENDS})
        endif()

        add_library(mo2::${LIBRARY} ALIAS mo2-${LIBRARY})
    endif()
endfunction()

#! mo2_find_bsatk : find and create a mo2::bsatk target
#
function(mo2_find_bsatk)
    mo2_find_corelib(bsatk DEPENDS boost::thread zlib lz4)
endfunction()

#! mo2_find_esptk : find and create a mo2::esptk target
#
function(mo2_find_esptk)
    mo2_find_corelib(esptk)
endfunction()

#! mo2_find_archive : find and create a mo2::archive target
#
function(mo2_find_archive)
    mo2_find_corelib(archive)
endfunction()

#! mo2_find_githubpp : find and create a mo2::githubpp target
#
function(mo2_find_githubpp)
    mo2_find_corelib(githubpp DEPENDS Qt::Core Qt::Network)
endfunction()

#! mo2_find_lootcli : find and create a mo2::lootcli target
#
function(mo2_find_lootcli)

    if (TARGET mo2-lootcli)
        return()
    endif()

    add_library(mo2-lootcli IMPORTED INTERFACE)
    target_include_directories(mo2-lootcli INTERFACE
        ${MO2_SUPER_PATH}/lootcli/include)
    add_library(mo2::lootcli ALIAS mo2-lootcli)

endfunction()

#! mo2_find_gamebryo : find and create a mo2::gamebryo target
#
function(mo2_find_gamebryo)

    # this does not use mo2_find_corelib because the target name do not match (we
    # want gamebryo, the target is game_gamebryo), and the src folder is not the same
    # other lib (src/gamebryo instead of src/)

    # target was already created
    if (TARGET mo2-gamebryo)
        return()
    endif()

    # if the target exists, we use it
    if (TARGET game_gamebryo)
        message(STATUS "Found existing game_gamebryo target, using it.")

        add_library(mo2-gamebryo ALIAS game_gamebryo)
        add_library(mo2::gamebryo ALIAS game_gamebryo)
    else()
        message(STATUS "Existing game_gamebryo target not found, creating it.")

        add_library(mo2-gamebryo IMPORTED STATIC)
        set_target_properties(mo2-gamebryo PROPERTIES
            IMPORTED_LOCATION ${MO2_INSTALL_LIBS_PATH}/game_gamebryo.lib)
        target_include_directories(mo2-gamebryo
            INTERFACE ${MO2_SUPER_PATH}/game_gamebryo/src/gamebryo)

        mo2_add_dependencies(mo2-gamebryo INTERFACE zlib lz4)

        add_library(mo2::gamebryo ALIAS mo2-gamebryo)
    endif()

endfunction()

#! mo2_find_creation : find and create a mo2::creation target
#
function(mo2_find_creation)

    # same as mo2_find_gamebryo, we do not use mo2_find_corelib (see mo2_find_gamebryo
    # comment for why)

    # target was already created
    if (TARGET mo2-creation)
        return()
    endif()

    # if the target exists, we use it
    if (TARGET game_creation)
        message(STATUS "Found existing game_creation target, using it.")

        add_library(mo2-creation ALIAS game_creation)
        add_library(mo2::creation ALIAS game_creation)
    else()
        message(STATUS "Existing game_creation target not found, creating it.")

        add_library(mo2-creation IMPORTED STATIC)
        set_target_properties(mo2-creation PROPERTIES
            IMPORTED_LOCATION ${MO2_INSTALL_LIBS_PATH}/game_creation.lib)
        target_include_directories(mo2-creation
            INTERFACE ${MO2_SUPER_PATH}/game_gamebryo/src/creation)

        add_library(mo2::creation ALIAS mo2-creation)

        mo2_add_dependencies(mo2-creation INTERFACE gamebryo lz4)
    endif()

endfunction()

#! mo2_find_loot : find and create a mo2::loot target
#
function(mo2_find_loot)
    if (TARGET mo2-loot)
        return()
    endif()

    mo2_required_variable(NAME LOOT_PATH TYPE PATH)

    find_package(Boost COMPONENTS locale REQUIRED)

    add_library(mo2-loot IMPORTED SHARED)
    set_target_properties(mo2-loot PROPERTIES IMPORTED_LOCATION ${LOOT_PATH}/bin/loot.dll)
    set_target_properties(mo2-loot PROPERTIES IMPORTED_IMPLIB ${LOOT_PATH}/lib/loot.lib)
    target_include_directories(mo2-loot INTERFACE ${LOOT_PATH}/include)
    target_link_libraries(mo2-loot INTERFACE ${Boost_LIBRARIES})
    add_library(mo2::loot ALIAS mo2-loot)
endfunction()

#! mo2_find_spdlog : find and carete a mo2::spdlog target
#
function(mo2_find_spdlog)
    if (TARGET mo2-spdlog)
        return()
    endif()

    mo2_required_variable(NAME SPDLOG_ROOT TYPE PATH)

    add_library(mo2-spdlog INTERFACE)
    target_compile_definitions(mo2-spdlog INTERFACE SPDLOG_USE_STD_FORMAT)
    target_include_directories(mo2-spdlog INTERFACE ${SPDLOG_ROOT}/include)
    add_library(mo2::spdlog ALIAS mo2-spdlog)

endfunction()

#! mo2_find_libbsarch : find and create a mo2::libbsarch target
#
function(mo2_find_libbsarch)
    if (TARGET mo2-libbsarch)
        return()
    endif()

    mo2_required_variable(NAME LIBBSARCH_ROOT TYPE PATH)

    add_library(mo2-libbsarch IMPORTED STATIC)
    set_target_properties(mo2-libbsarch PROPERTIES
        IMPORTED_LOCATION
        ${LIBBSARCH_ROOT}/libbsarch.lib
    )
    target_include_directories(mo2-libbsarch INTERFACE ${LIBBSARCH_ROOT})
    target_link_libraries(mo2-libbsarch INTERFACE ${LIBBSARCH_ROOT}/libbsarch_OOP.lib)
    add_library(mo2::libbsarch ALIAS mo2-libbsarch)

endfunction()

#! mo2_find_zlib : find and carete a mo2::zlib target
#
function(mo2_find_zlib)
    if (TARGET mo2-zlib)
        return()
    endif()

    mo2_required_variable(NAME ZLIB_ROOT TYPE PATH)

    # not using find_package(ZLIB) because we want the static version
    add_library(mo2-zlib IMPORTED STATIC)
    set_target_properties(mo2-zlib PROPERTIES
        IMPORTED_LOCATION ${ZLIB_ROOT}/lib/zlibstatic.lib)
    target_include_directories(mo2-zlib INTERFACE ${ZLIB_ROOT}/include)
    add_library(mo2::zlib ALIAS mo2-zlib)

endfunction()

#! mo2_find_lz4 : find and carete a mo2::lz4 target
#
function(mo2_find_lz4)
    if (TARGET mo2-lz4)
        return()
    endif()

    mo2_required_variable(NAME LZ4_ROOT TYPE PATH)

    add_library(mo2-lz4 IMPORTED SHARED)
    set_target_properties(mo2-lz4 PROPERTIES
        IMPORTED_LOCATION ${LZ4_ROOT}/bin/liblz4.dll
        IMPORTED_IMPLIB ${LZ4_ROOT}/bin/liblz4.lib
    )
    target_include_directories(mo2-lz4 INTERFACE ${LZ4_ROOT}/lib)

    add_library(mo2::lz4 ALIAS mo2-lz4)

endfunction()

#! mo2_find_7z : find and carete a mo2::7z target
#
function(mo2_find_7z)
    if (TARGET mo2-7z)
        return()
    endif()

    mo2_required_variable(NAME SEVENZ_ROOT TYPE PATH)

    add_library(mo2-7z INTERFACE)
    target_include_directories(mo2-7z INTERFACE ${SEVENZ_ROOT}/CPP)

    add_library(mo2::7z ALIAS mo2-7z)

endfunction()

#! mo2_find_tomlplusplus : find and create a mo2::tomlplusplus target
#
function(mo2_find_tomlplusplus)
    if (TARGET mo2-tomlplusplus)
        return()
    endif()

    FetchContent_Declare(
        tomlplusplus
        URL "https://github.com/marzer/tomlplusplus/archive/v3.2.0.tar.gz"
        URL_HASH "SHA256=aeba776441df4ac32e4d4db9d835532db3f90fd530a28b74e4751a2915a55565"
    )
    FetchContent_MakeAvailable(tomlplusplus)

    add_library(mo2-tomlplusplus INTERFACE)
    target_include_directories(mo2-tomlplusplus INTERFACE "${tomlplusplus_SOURCE_DIR}/include")
    add_dependencies(mo2-tomlplusplus tomlplusplus)

    add_library(mo2::tomlplusplus ALIAS mo2-tomlplusplus)

endfunction()

#! mo2_find_usvfs : find and create a mo2::usvfs target
#
function(mo2_find_usvfs)
    if (TARGET mo2-usvfs)
        return()
    endif()

    set(USVFS_PATH "${MO2_BUILD_PATH}/usvfs")
    set(USVFS_INC_PATH "${USVFS_PATH}/include")
    set(USVFS_LIB_PATH "${USVFS_PATH}/lib")

    add_library(mo2-usvfs IMPORTED SHARED)
    set_target_properties(mo2-usvfs PROPERTIES
        IMPORTED_LOCATION "${USVFS_LIB_PATH}/usvfs_x64.dll"
    )
    set_target_properties(mo2-usvfs PROPERTIES
        IMPORTED_IMPLIB "${USVFS_LIB_PATH}/usvfs_x64.lib"
    )
    target_include_directories(mo2-usvfs INTERFACE ${USVFS_INC_PATH})

    add_library(mo2::usvfs ALIAS mo2-usvfs)

endfunction()

#! mo2_find_libraries : find and create libraries to link to
#
# this function tries to find the given libraries and generates (if the libraries are
# found) targets mo2::LIBRARY_NAME for each library found
#
# example: mo2_find_libraries(uibase loot) will create mo2::uibase and mo2::loot
#
# available libraries are the ones with mo2_find_XXX functions
#
function(mo2_find_libraries)
    foreach(target ${ARGN})
        cmake_language(CALL "mo2_find_${target}")
    endforeach()
endfunction()
