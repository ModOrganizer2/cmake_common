cmake_minimum_required(VERSION 3.16)

if (DEFINED MO2_INCLUDED)
	return()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/mo2_utils.cmake)

# setup path for find_package(), etc.
mo2_required_variable(NAME BOOST_ROOT TYPE PATH)
mo2_required_variable(NAME BOOST_LIBRARYDIR TYPE PATH)
mo2_required_variable(NAME QT_ROOT TYPE PATH)
mo2_required_variable(NAME FMT_ROOT TYPE PATH)
mo2_required_variable(NAME SPDLOG_ROOT TYPE PATH)
mo2_required_variable(NAME LOOT_PATH TYPE PATH)
mo2_required_variable(NAME LZ4_ROOT TYPE PATH)
mo2_required_variable(NAME ZLIB_ROOT TYPE PATH)
mo2_required_variable(NAME PYTHON_ROOT TYPE PATH)
mo2_required_variable(NAME SEVENZ_ROOT TYPE PATH)
mo2_required_variable(NAME LIBBSARCH_ROOT TYPE PATH)
mo2_required_variable(NAME CMAKE_INSTALL_PREFIX TYPE PATH)

get_filename_component(MO2_BUILD_PATH "${CMAKE_CURRENT_LIST_DIR}/../.." REALPATH)
get_filename_component(MO2_SUPER_PATH "${MO2_BUILD_PATH}/modorganizer_super" REALPATH)
get_filename_component(MO2_UIBASE_PATH "${MO2_SUPER_PATH}/uibase" REALPATH)
get_filename_component(MO2_INSTALL_PATH "${MO2_SUPER_PATH}/../../install" REALPATH)
get_filename_component(MO2_INSTALL_LIBS_PATH "${MO2_INSTALL_PATH}/libs" REALPATH)

list(APPEND CMAKE_PREFIX_PATH
	${QT_ROOT}/lib/cmake
	${LZ4_ROOT}/dll
	${FMT_ROOT}/build
	${BOOST_ROOT}/build
	${MO2_BUILD_PATH}/googletest/build/lib/cmake/GTest)

# we add the Qt DLL to the paths for some tools
set(ENV{PATH} "${QT_ROOT}/bin;$ENV{PATH}")

# custom property, used to keep track of the type of target
define_property(TARGET PROPERTY MO2_TARGET_TYPE INHERITED)

set(Boost_USE_STATIC_RUNTIME OFF)
set(Boost_USE_STATIC_LIBS ON)
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set_property(GLOBAL PROPERTY AUTOGEN_SOURCE_GROUP autogen)
set_property(GLOBAL PROPERTY AUTOMOC_SOURCE_GROUP autogen)
set_property(GLOBAL PROPERTY AUTORCC_SOURCE_GROUP autogen)

include(${CMAKE_CURRENT_LIST_DIR}/mo2_cpp.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/mo2_python.cmake)

# mark as included
set(MO2_DEFINED true)
