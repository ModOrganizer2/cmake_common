macro(do_cpp_project)
	set(Boost_USE_STATIC_RUNTIME OFF)
	set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
	set(CMAKE_INSTALL_MESSAGE NEVER)
	set(CMAKE_AUTOMOC ON)
	set(CMAKE_AUTOUIC ON)
	set(CMAKE_AUTORCC ON)

	find_package(Qt6 COMPONENTS Widgets REQUIRED)
	find_package(Qt6 COMPONENTS QuickWidgets REQUIRED)
	find_package(Qt6 COMPONENTS Quick REQUIRED)
	find_package(Qt6 COMPONENTS Network REQUIRED)
	find_package(Qt6 COMPONENTS WebEngineWidgets REQUIRED)
	find_package(Qt6 COMPONENTS WebSockets REQUIRED)
	find_package(Qt6 COMPONENTS Concurrent REQUIRED)
	find_package(Qt6 COMPONENTS Qml REQUIRED)
	find_package(Qt6 COMPONENTS LinguistTools REQUIRED)
	find_package(Qt6 COMPONENTS OpenGLWidgets REQUIRED)
	find_package(ZLIB REQUIRED)
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
		VS_STARTUP_PROJECT ${PROJECT_NAME})
endmacro()


macro(cpp_pre_target)
	if(DEFINED AUTOGEN_BUILD_DIR)
		set(UI_HEADERS_DIR ${AUTOGEN_BUILD_DIR})
	else()
		set(UI_HEADERS_DIR ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_autogen/include_RelWithDebInfo)
	endif()

	file(GLOB_RECURSE source_files CONFIGURE_DEPENDS *.cpp)
	file(GLOB_RECURSE header_files CONFIGURE_DEPENDS *.h)
	file(GLOB_RECURSE qrc_files CONFIGURE_DEPENDS *.qrc)
	file(GLOB_RECURSE rc_files CONFIGURE_DEPENDS *.rc)
	file(GLOB_RECURSE ui_files CONFIGURE_DEPENDS *.ui)
	file(GLOB_RECURSE ui_header_files CONFIGURE_DEPENDS ${UI_HEADERS_DIR}/*.h)
	file(GLOB_RECURSE rule_files CONFIGURE_DEPENDS ${CMAKE_BINARY_DIR}/*.rule)
	file(GLOB_RECURSE misc_files CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.natvis)

	if(${create_translations})
		qt_add_lupdate(
		    ${PROJECT_NAME} TS_FILES ${CMAKE_SOURCE_DIR}/src/${PROJECT_NAME}_en.ts
			QM_FILES_OUTPUT_VARIABLE qm_files
			SOURCES ${source_files} ${header_files} ${ui_files} ${additional_translations}
			LUPDATE_OPTIONS -silent
		)
	endif()

	set(input_files
		${source_files}
		${header_files}
		${ui_files}
		${ui_header_files}
		${qrc_files}
		${rc_files}
		${misc_files}
		${qm_files})

	# this needs to happen before the include() below because they're only used
	# when creating the target

    if(DEFINED DEPENDENCIES_DIR)
	    set(gtest_directory ${DEPENDENCIES_DIR}/googletest)
    else()
        set(gtest_directory ${modorganizer_build_path}/googletest)
	endif()

	link_directories(
		${modorganizer_install_lib_path}
		${Boost_LIBRARY_DIRS}
		${LZ4_ROOT}/bin
		${ZLIB_ROOT}/lib
		${LOOT_PATH}
		${LIBBSARCH_ROOT}
		${gtest_directory}/build/lib
	)
endmacro()



macro(cpp_post_target)
	target_include_directories(${PROJECT_NAME} PRIVATE
		${Boost_INCLUDE_DIRS}
		${SPDLOG_ROOT}/include
		${SEVENZ_ROOT}/CPP
		${ZLIB_INCLUDE_DIRS}
		${LZ4_ROOT}/lib
	)

	source_group(src REGULAR_EXPRESSION ".*\\.(h|cpp)")
	source_group(ui REGULAR_EXPRESSION ".*\\.ui")
	source_group(cmake FILES CMakeLists.txt)
	source_group(autogen FILES ${rule_files} ${qm_files} ${ui_header_files})
	source_group(autogen REGULAR_EXPRESSION ".*\\cmake_pch.*")
	source_group(resources FILES ${rc_files} ${qrc_files})

	if(EXISTS ${CMAKE_SOURCE_DIR}/src/pch.h)
		target_precompile_headers(${PROJECT_NAME}
			PRIVATE ${CMAKE_SOURCE_DIR}/src/pch.h)
	endif()

    if(${enable_cli})
        if (CMAKE_GENERATOR MATCHES "Visual Studio")
            set_target_properties(${PROJECT_NAME} PROPERTIES
                COMMON_LANGUAGE_RUNTIME "")
        else()
            set(COMPILE_FLAGS "${COMPILE_FLAGS} /clr")
            string(REPLACE "/EHs" "/EHa" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
        endif()
    endif()

	set_target_properties(${PROJECT_NAME} PROPERTIES
		COMPILE_FLAGS "${COMPILE_FLAGS}")

	set_target_properties(${PROJECT_NAME} PROPERTIES
		COMPILE_FLAGS_RELWITHDEBINFO "${OPTIMIZE_COMPILE_FLAGS}")

	set_target_properties(${PROJECT_NAME} PROPERTIES
		LINK_FLAGS_RELWITHDEBINFO "${OPTIMIZE_LINK_FLAGS}")

	target_link_libraries(${PROJECT_NAME}
		Qt::Widgets
		Qt::WebEngineWidgets
		Qt::Quick
		Qt::Qml
		Qt::QuickWidgets
		Qt::Network
		Qt::WebSockets
		Qt::Concurrent
		fmt::fmt
		liblz4 zlibstatic
		${Boost_LIBRARIES}
		Dbghelp Version Shlwapi
	)

	if(NOT ${PROJECT_NAME} STREQUAL "uibase")
		requires_project("uibase")
	endif()

	if(${run_elevated})
		set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS
			"/MANIFESTUAC:\"level='requireAdministrator' uiAccess='false'\"")
	endif()
endmacro()


function(add_filter)
	cmake_parse_arguments(PARSE_ARGV 0 add_filter "" "NAME" "FILES;GROUPS")

	set(files ${add_filter_FILES})

	foreach(f ${add_filter_GROUPS})
		set(files ${files} ${f}.cpp ${f}.h ${f}.inc)
	endforeach()

	string(REPLACE "/" "\\" filter_name ${add_filter_NAME})
	source_group(${filter_name} FILES ${files})
endfunction()


function(requires_project)
	cmake_parse_arguments(PARSE_ARGV 0 requires "" "" "")

	foreach(name ${requires_UNPARSED_ARGUMENTS})
		if(${name} STREQUAL "game_gamebryo")
		    if(${PROJECT_NAME} STREQUAL "game_creation")
		        set(src_dirs "../gamebryo")
            else()
                set(src_dirs
                    "${modorganizer_super_path}/game_gamebryo/src/gamebryo"
    				"${modorganizer_super_path}/game_gamebryo/src/creation")
            endif()

			set(include_dirs ${src_dirs})
			set(libs "")

			if(NOT ${PROJECT_NAME} STREQUAL "game_gamebryo")
				set(libs ${libs} game_gamebryo)
			endif()

			if(NOT ${PROJECT_NAME} STREQUAL "game_creation")
				set(libs ${libs} game_creation)
			endif()
		elseif(${name} STREQUAL "usvfs")
			set(src_dirs "${modorganizer_build_path}/usvfs/src")
			set(include_dirs "${modorganizer_build_path}/usvfs/include")
			set(libs "usvfs_x64")
        elseif(${name} STREQUAL "uibase")
		    if(${PROJECT_NAME} STREQUAL "uibasetests")
		        set(src_dirs "../src")
            else()
                set(src_dirs
                    "${modorganizer_super_path}/uibase/src"
    				"${modorganizer_super_path}/uibase/tests")
            endif()

			set(include_dirs ${src_dirs})
			set(libs "uibase")
		else()
			set(src_dirs "${modorganizer_super_path}/${name}/src")
			set(include_dirs ${src_dirs})
			set(libs ${name})
		endif()

		target_include_directories(${PROJECT_NAME} PRIVATE ${include_dirs})

		set(has_source_files FALSE)
		foreach(src_dir ${src_dirs})
			file(GLOB_RECURSE source_files "${src_dir}/*.cpp")
			if(NOT "X${source_files}" STREQUAL "X")
				set(has_source_files TRUE)
				break()
			endif()
		endforeach()

		if(${has_source_files})
			target_link_libraries(${PROJECT_NAME} ${libs})
		endif()
	endforeach()
endfunction()


function(requires_library)
	cmake_parse_arguments(PARSE_ARGV 0 requires "" "" "")

	foreach(name ${requires_UNPARSED_ARGUMENTS})
		if(${name} STREQUAL "loot")
			target_include_directories(${PROJECT_NAME} PRIVATE
				${LOOT_PATH}/include)

			target_link_libraries(${PROJECT_NAME} loot)
		elseif(${name} STREQUAL "cpptoml")
			include(ExternalProject)

			ExternalProject_Add(
				cpptoml
				PREFIX "external"
				URL "https://github.com/skystrife/cpptoml/archive/2051836a96a25e5a2d5283be7f633a157848f15e.tar.gz"
				CONFIGURE_COMMAND ""
				BUILD_COMMAND ""
				INSTALL_COMMAND "")

			ExternalProject_Get_Property(cpptoml SOURCE_DIR)

			target_include_directories(${PROJECT_NAME} PRIVATE
				"${SOURCE_DIR}/include")

			add_dependencies(${PROJECT_NAME} cpptoml)
		elseif(${name} STREQUAL "gtest")
            if(DEFINED DEPENDENCIES_DIR)
                set(gtest_directory ${DEPENDENCIES_DIR}/googletest)
            else()
                set(gtest_directory ${modorganizer_build_path}/googletest)
            endif()
            target_include_directories(${PROJECT_NAME} PRIVATE
                ${gtest_directory}/googletest/include
                ${gtest_directory}/googlemock/include)

			target_link_libraries(${PROJECT_NAME} gtest)
			target_link_libraries(${PROJECT_NAME} gmock)
			target_link_libraries(${PROJECT_NAME} gtest_main)
		elseif(${name} STREQUAL "python")
			target_include_directories(${PROJECT_NAME} PRIVATE
				${PYTHON_ROOT}/Include)
		elseif(${name} STREQUAL "libbsarch")
			target_include_directories(${PROJECT_NAME} PRIVATE
				${LIBBSARCH_ROOT})

			target_link_libraries(${PROJECT_NAME} libbsarch libbsarch_OOP)
		else()
			message(FATAL_ERROR "unknown library ${name}")
		endif()
	endforeach()
endfunction()

