cmake_minimum_required(VERSION 3.16)

function(required_variable name type)
	if(ARGN)
		list(GET ${ARGN} 0 description)
	else()
		set(description "${name}")
	endif()
	
	if(NOT DEFINED ${name})
		message(FATAL_ERROR "${name} is not defined")
	endif()

	set(${name} ${${name}} CACHE ${type} "${description}")
endfunction()


function(get_real_path out path)
	set(p ${path})
	get_filename_component(p ${p} REALPATH)
	set(${out} ${p} PARENT_SCOPE)
endfunction()


if(NOT DEFINED enable_warnings)
	set(enable_warnings ON)
endif()

if(NOT DEFINED enable_permissive)
	set(enable_permissive OFF)
endif()

if(NOT DEFINED enable_cli)
    set(enable_cli OFF)
endif()

if(NOT DEFINED enable_bigobj)
    set(enable_bigobj OFF)
endif()

if(NOT DEFINED create_translations)
	set(create_translations ON)
endif()

if(NOT DEFINED additional_translations)
	set(additional_translations "")
endif()

if(NOT DEFINED run_elevated)
	set(run_elevated OFF)
endif()



set(COMPILE_FLAGS "/std:c++latest /MP")
set(OPTIMIZE_COMPILE_FLAGS "/O2")
set(OPTIMIZE_LINK_FLAGS "/LTCG /INCREMENTAL:NO /OPT:REF /OPT:ICF")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(${enable_warnings})
	set(COMPILE_FLAGS "${COMPILE_FLAGS} /Wall /wd4464")
endif()

if(NOT ${enable_permissive})
	set(COMPILE_FLAGS "${COMPILE_FLAGS} /permissive-")
endif()

if(${enable_bigobj})
    set(COMPILE_FLAGS "${COMPILE_FLAGS} /bigobj")
endif()

required_variable(BOOST_ROOT PATH)
required_variable(BOOST_LIBRARYDIR PATH)
required_variable(QT_ROOT PATH)
required_variable(FMT_ROOT PATH)
required_variable(SPDLOG_ROOT PATH)
required_variable(LOOT_PATH PATH)
required_variable(LZ4_ROOT PATH)
required_variable(ZLIB_ROOT PATH)
required_variable(PYTHON_ROOT PATH)
required_variable(SEVENZ_ROOT PATH)
required_variable(LIBBSARCH_ROOT PATH)
required_variable(CMAKE_INSTALL_PREFIX PATH)

get_real_path(modorganizer_build_path "${CMAKE_CURRENT_LIST_DIR}/../..")
get_real_path(modorganizer_super_path "${modorganizer_build_path}/modorganizer_super")
get_real_path(uibase_path "${modorganizer_super_path}/uibase")
get_real_path(uibase_include_path "${uibase_path}/src")
get_real_path(modorganizer_install_path "${modorganizer_super_path}/../../install")
get_real_path(modorganizer_install_lib_path "${modorganizer_install_path}/libs")

list(APPEND CMAKE_PREFIX_PATH
	${QT_ROOT}/lib/cmake
	${LZ4_ROOT}/dll
	${FMT_ROOT}/build
	${BOOST_ROOT}/build)


if(${project_type} STREQUAL "plugin")
	include(${CMAKE_CURRENT_LIST_DIR}/plugin.cmake)
elseif(${project_type} STREQUAL "dll")
	include(${CMAKE_CURRENT_LIST_DIR}/dll.cmake)
elseif(${project_type} STREQUAL "lib")
	include(${CMAKE_CURRENT_LIST_DIR}/lib.cmake)
elseif(${project_type} STREQUAL "exe")
	include(${CMAKE_CURRENT_LIST_DIR}/exe.cmake)
elseif(${project_type} STREQUAL "tests")
	include(${CMAKE_CURRENT_LIST_DIR}/tests.cmake)
elseif(${project_type} STREQUAL "python_plugin")
	include(${CMAKE_CURRENT_LIST_DIR}/python_plugin.cmake)
elseif(${project_type} STREQUAL "python_module_plugin")
	include(${CMAKE_CURRENT_LIST_DIR}/python_module_plugin.cmake)
else()
	message(FATAL_ERROR "unknown project type '${project_type}'")
endif()


do_project()
