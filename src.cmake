cmake_minimum_required(VERSION 3.16)

function(add_filter)
	cmake_parse_arguments(PARSE_ARGV 0 add_filter "" "NAME" "FILES;GROUPS")

	set(files ${add_filter_FILES})

	foreach(f ${add_filter_GROUPS})
		set(files ${files} ${f}.cpp ${f}.h ${f}.inc ${f}.ui)
	endforeach()

	string(REPLACE "/" "\\" filter_name ${add_filter_NAME})
	source_group(${filter_name} FILES ${files})
endfunction()


file(GLOB_RECURSE source_files CONFIGURE_DEPENDS *.cpp)
file(GLOB_RECURSE header_files CONFIGURE_DEPENDS *.h)
file(GLOB_RECURSE qrc_files CONFIGURE_DEPENDS *.qrc)
file(GLOB_RECURSE rc_files CONFIGURE_DEPENDS *.rc)
file(GLOB_RECURSE rule_files CONFIGURE_DEPENDS ${CMAKE_BINARY_DIR}/*.rule)
file(GLOB_RECURSE misc_files CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.natvis)

if(${create_translations})
	qt5_create_translation(
		qm_files
		${CMAKE_SOURCE_DIR}/src ${additional_translations}
		${CMAKE_SOURCE_DIR}/src/${CMAKE_PROJECT_NAME}_en.ts
		#OPTIONS -silent
	)
endif()

include_directories(${uibase_include_path} ${Boost_INCLUDE_DIRS} ${SPDLOG_ROOT}/include)

link_directories(
	${modorganizer_install_lib_path}
	${Boost_LIBRARY_DIRS}
	${LZ4_ROOT}/bin
	${ZLIB_ROOT}/lib
)

set(input_files
	${source_files} ${header_files} ${qm_files} ${qrc_files}
	${rc_files} ${misc_files})

source_group(src REGULAR_EXPRESSION ".*\\.(h|cpp|ui)")
source_group(cmake FILES CMakeLists.txt)
source_group(autogen FILES ${rule_files} ${qm_files})
source_group(autogen REGULAR_EXPRESSION ".*\\cmake_pch.*")
source_group(resources FILES ${rc_files} ${qrc_files})

if(${project_type} STREQUAL "plugin")
	include(c:/tmp/cmake_common/plugin.cmake)
elseif(${project_type} STREQUAL "dll")
	include(c:/tmp/cmake_common/dll.cmake)
elseif(${project_type} STREQUAL "exe")
	include(c:/tmp/cmake_common/exe.cmake)
else()
	message(FATAL_ERROR "unknown project type '${project_type}'")
endif()

if(EXISTS ${CMAKE_SOURCE_DIR}/src/pch.h)
	target_precompile_headers(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/src/pch.h)
	#set(CMAKE_AUTOMOC_MOC_OPTIONS "-bpch.h")
endif()

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES COMPILE_FLAGS "${COMPILE_FLAGS}")
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES COMPILE_FLAGS_RELWITHDEBINFO "${OPTIMIZE_COMPILE_FLAGS}")
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES LINK_FLAGS_RELWITHDEBINFO "${OPTIMIZE_LINK_FLAGS}")

target_link_libraries(${CMAKE_PROJECT_NAME}
	Qt5::Widgets
	Qt5::WinExtras
	Qt5::WebEngineWidgets
	Qt5::Quick
	Qt5::Qml
	Qt5::QuickWidgets
	Qt5::Network
	Qt5::WebSockets
	fmt::fmt
	liblz4 zlibstatic
	${Boost_LIBRARIES}
	Dbghelp Version Shlwapi
)
