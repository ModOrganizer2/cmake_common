macro(do_cpp_project)
	set(Boost_USE_STATIC_RUNTIME OFF)
	set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
	set(CMAKE_INSTALL_MESSAGE NEVER)
	set(CMAKE_AUTOMOC ON)
	set(CMAKE_AUTOUIC ON)
	set(CMAKE_AUTORCC ON)

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

	execute_process(
	  COMMAND git log -1 --format=%h
	  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
	  OUTPUT_VARIABLE GIT_COMMIT_HASH
	  OUTPUT_STRIP_TRAILING_WHITESPACE
	)

	add_compile_definitions(
		_UNICODE
		UNICODE
		NOMINMAX
		_CRT_SECURE_NO_WARNINGS
		BOOST_CONFIG_SUPPRESS_OUTDATED_MESSAGE
		_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
		QT_MESSAGELOGCONTEXT
		GITID="${GIT_COMMIT_HASH}")

	set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY
		VS_STARTUP_PROJECT ${CMAKE_PROJECT_NAME})
endmacro()


macro(cpp_pre_target)
	if(${create_translations})
		qt5_create_translation(
			qm_files
			${CMAKE_SOURCE_DIR}/src ${additional_translations}
			${CMAKE_SOURCE_DIR}/src/${CMAKE_PROJECT_NAME}_en.ts
			OPTIONS -silent
		)
	endif()

	file(GLOB_RECURSE source_files CONFIGURE_DEPENDS *.cpp)
	file(GLOB_RECURSE header_files CONFIGURE_DEPENDS *.h)
	file(GLOB_RECURSE qrc_files CONFIGURE_DEPENDS *.qrc)
	file(GLOB_RECURSE rc_files CONFIGURE_DEPENDS *.rc)
	file(GLOB_RECURSE rule_files CONFIGURE_DEPENDS ${CMAKE_BINARY_DIR}/*.rule)
	file(GLOB_RECURSE misc_files CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.natvis)

	set(input_files
		${source_files}
		${header_files}
		${qrc_files}
		${rc_files}
		${misc_files}
		${qm_files})

	# this needs to happen before the include() below because they're only used
	# when creating the target
	link_directories(
		${modorganizer_install_lib_path}
		${Boost_LIBRARY_DIRS}
		${LZ4_ROOT}/bin
		${ZLIB_ROOT}/lib
	)
endmacro()



macro(cpp_post_target)
	# this needs to happen after the include() above because they rely on the
	# target being created
	target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
		${Boost_INCLUDE_DIRS}
		${SPDLOG_ROOT}/include
		${SEVENZ_ROOT}/CPP
		${ZLIB_INCLUDE_DIRS}
		${LZ4_ROOT}/lib
	)

	source_group(src REGULAR_EXPRESSION ".*\\.(h|cpp|ui)")
	source_group(cmake FILES CMakeLists.txt)
	source_group(autogen FILES ${rule_files} ${qm_files})
	source_group(autogen REGULAR_EXPRESSION ".*\\cmake_pch.*")
	source_group(resources FILES ${rc_files} ${qrc_files})

	if(EXISTS ${CMAKE_SOURCE_DIR}/src/pch.h)
		target_precompile_headers(${CMAKE_PROJECT_NAME}
			PRIVATE ${CMAKE_SOURCE_DIR}/src/pch.h)
	endif()

	set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
		COMPILE_FLAGS "${COMPILE_FLAGS}")

	set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
		COMPILE_FLAGS_RELWITHDEBINFO "${OPTIMIZE_COMPILE_FLAGS}")

	set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
		LINK_FLAGS_RELWITHDEBINFO "${OPTIMIZE_LINK_FLAGS}")

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

	if(NOT ${CMAKE_PROJECT_NAME} STREQUAL "uibase")
		requires_project("uibase")
	endif()
endmacro()


function(add_filter)
	cmake_parse_arguments(PARSE_ARGV 0 add_filter "" "NAME" "FILES;GROUPS")

	set(files ${add_filter_FILES})

	foreach(f ${add_filter_GROUPS})
		set(files ${files} ${f}.cpp ${f}.h ${f}.inc ${f}.ui)
	endforeach()

	string(REPLACE "/" "\\" filter_name ${add_filter_NAME})
	source_group(${filter_name} FILES ${files})
endfunction()


function(requires_project)
	cmake_parse_arguments(PARSE_ARGV 0 requires "" "" "")

	foreach(project_name ${requires_UNPARSED_ARGUMENTS})
		if(${project_name} STREQUAL "game_gamebryo")
			set(src_dirs
				"${modorganizer_super_path}/game_gamebryo/src/gamebryo"
				"${modorganizer_super_path}/game_gamebryo/src/creation")

			set(libs game_gamebryo game_creation)
		else()
			set(src_dirs "${modorganizer_super_path}/${project_name}/src")
			set(libs ${project_name})
		endif()

		target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${src_dirs})

		set(has_source_files FALSE)
		foreach(src_dir ${src_dirs})
			file(GLOB_RECURSE source_files "${src_dir}/*.cpp")
			if(NOT "X${source_files}" STREQUAL "X")
				set(has_source_files TRUE)
				break()
			endif()
		endforeach()

		if(${has_source_files})
			target_link_libraries(${CMAKE_PROJECT_NAME} ${libs})
		endif()
	endforeach()
endfunction()
