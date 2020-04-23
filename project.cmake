cmake_minimum_required(VERSION 3.16)

function(required_variable name)
	if(NOT DEFINED ${name})
		message(FATAL_ERROR "${name} is not defined")
	endif()
endfunction()


function(get_real_path out path)
	set(p ${path})
	get_filename_component(p ${p} REALPATH)
	set(${out} ${p} PARENT_SCOPE)
endfunction()


if(NOT DEFINED enable_warnings)
	set(enable_warnings OFF)
endif()

if(NOT DEFINED create_translations)
	set(create_translations ON)
endif()

if(NOT DEFINED additional_translations)
	set(additional_translations "")
endif()


#temp
set(QT_ROOT "C:/dev/qt/5.14.1/msvc2017_64")
set(LZ4_ROOT "C:/dev/projects/modorganizer/build/lz4-v1.9.2")
set(FMT_ROOT "C:/dev/projects/modorganizer/build/fmt-6.1.2")
set(ZLIB_ROOT "C:/dev/projects/modorganizer/build/zlib-1.2.11")
set(BOOST_ROOT "C:/dev/projects/modorganizer/build/boost_1_72_0")
set(BOOST_LIBRARYDIR "${BOOST_ROOT}/lib64-msvc-14.2/lib")
set(SPDLOG_ROOT "C:/dev/projects/modorganizer/build/spdlog-v1.4.2")
set(COMPILE_FLAGS "/std:c++latest /permissive- /MP")
set(OPTIMIZE_COMPILE_FLAGS "/O2")
set(OPTIMIZE_LINK_FLAGS "/LTCG /INCREMENTAL:NO /OPT:REF /OPT:ICF")
set(CMAKE_INSTALL_PREFIX "C:/dev/projects/modorganizer/install")

if (${enable_warnings})
	set(COMPILE_FLAGS "${COMPILE_FLAGS} /Wall /wd4464")
endif()

required_variable(QT_ROOT)
required_variable(LZ4_ROOT)
required_variable(FMT_ROOT)
required_variable(ZLIB_ROOT)
required_variable(BOOST_ROOT)
required_variable(BOOST_LIBRARYDIR)
required_variable(SPDLOG_ROOT)

required_variable(COMPILE_FLAGS)
required_variable(OPTIMIZE_COMPILE_FLAGS)
required_variable(OPTIMIZE_LINK_FLAGS)
required_variable(CMAKE_INSTALL_PREFIX)


get_real_path(modorganizer_build_path ${CMAKE_CURRENT_SOURCE_DIR}/../..)
get_real_path(modorganizer_super_path "${modorganizer_build_path}/modorganizer_super")
get_real_path(uibase_path ${modorganizer_super_path}/uibase)
get_real_path(uibase_include_path ${uibase_path}/src)
get_real_path(modorganizer_install_path "${modorganizer_super_path}/../../install")
get_real_path(modorganizer_install_lib_path "${modorganizer_install_path}/libs")

set(Boost_USE_STATIC_RUNTIME OFF)

list(APPEND CMAKE_PREFIX_PATH ${QT_ROOT}/lib/cmake)
list(APPEND CMAKE_PREFIX_PATH ${LZ4_ROOT}/dll)
list(APPEND CMAKE_PREFIX_PATH ${FMT_ROOT}/build)
list(APPEND CMAKE_PREFIX_PATH ${BOOST_ROOT}/build)

find_package(Qt5Widgets REQUIRED)
find_package(Qt5QuickWidgets REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5WinExtras REQUIRED)
find_package(Qt5WebEngineWidgets REQUIRED)
find_package(Qt5WebSockets REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5LinguistTools)
find_package(zlib REQUIRED)
find_package(Boost REQUIRED COMPONENTS thread)
find_package(fmt REQUIRED)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set_property(GLOBAL PROPERTY AUTOGEN_SOURCE_GROUP autogen)
set_property(GLOBAL PROPERTY AUTOMOC_SOURCE_GROUP autogen)
set_property(GLOBAL PROPERTY AUTORCC_SOURCE_GROUP autogen)

set(CMAKE_AUTOMOC on)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

execute_process(
  COMMAND git log -1 --format=%h
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE GIT_COMMIT_HASH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

add_definitions(
	-D_UNICODE -DUNICODE
	-DNOMINMAX
	-D_CRT_SECURE_NO_WARNINGS
	-DBOOST_CONFIG_SUPPRESS_OUTDATED_MESSAGE
	-D_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
	-DQT_MESSAGELOGCONTEXT
	-DGITID="${GIT_COMMIT_HASH}")

set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
set(CMAKE_INSTALL_MESSAGE NEVER)

set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY
	VS_STARTUP_PROJECT ${CMAKE_PROJECT_NAME})
