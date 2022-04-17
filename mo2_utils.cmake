# this file contains utility code that is not directly related to MO2
cmake_minimum_required(VERSION 3.16)

include(CMakeParseArguments)

if (DEFINED MO2_UTILS_DEFINED)
	return()
endif()

#! mo2_set_if_not_defined : set a variable to the given value if not defined
#
# \param:NAME name of the variable
# \param:VALUE value of the variable to set (if not defined)
#
function (mo2_set_if_not_defined NAME VALUE)
	if (NOT DEFINED ${NAME})
		set(${NAME} ${VALUE} PARENT_SCOPE)
	endif()
endfunction()

#! mo2_set_project_to_run_from_install : set a PROJECT to run from a given executable
#
# this function only works for VS generator
#
# \param:PROJECT name of the project
# \param:EXECUTABLE full path to the executable
# \param:WORKDIR working directory (optional, default is the directory of the executable)
#
function(mo2_set_project_to_run_from_install)
	cmake_parse_arguments(MO2 "" "PROJECT;EXECUTABLE;WORKDIR" "" ${ARGN})

	set(vcxproj_user_file "${CMAKE_CURRENT_BINARY_DIR}/${MO2_PROJECT}.vcxproj.user")

    # extract directory
    if (NOT DEFINED MO2_WORKDIR)
        get_filename_component(MO2_WORKDIR ${MO2_EXECUTABLE} DIRECTORY )
    endif()

	if(NOT EXISTS ${vcxproj_user_file})
		file(WRITE ${vcxproj_user_file}
			"<?xml version=\"1.0\" encoding=\"utf-8\"?>
				<Project ToolsVersion=\"Current\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">
				  <PropertyGroup>
					<LocalDebuggerWorkingDirectory>${MO2_WORKDIR}</LocalDebuggerWorkingDirectory>
					<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>
					<LocalDebuggerCommand>${MO2_EXECUTABLE}</LocalDebuggerCommand>
				  </PropertyGroup>
				</Project>")
	endif()
endfunction()

#! mo2_required_variable : check that a variable is defined, fails otherwise
#
# this function checks that a variable with the given NAME is defined, if it's not
# it fails with a FATAL_ERROR, otherwise it caches the variable
#
# \param:NAME name of the variable
# \param:TYPE type of the variable (optional)
# \param:DESC description of the variable (optional)
#
macro(mo2_required_variable)
	cmake_parse_arguments(REQ_VAR "" "NAME;TYPE;DESC" "" ${ARGN})

	if(NOT DEFINED REQ_VAR_DESC)
		set(REQ_VAR_DESC "${name}")
	endif()

	if(NOT DEFINED ${REQ_VAR_NAME})
		message(FATAL_ERROR "${REQ_VAR_NAME} is not defined")
	endif()

	set(${REQ_VAR_NAME} ${${REQ_VAR_NAME}} CACHE ${REQ_VAR_TYPE} "${REQ_VAR_DESC}")
endmacro()

#! mo2_add_filter : add source_group based on the given names
#
# \param:NAME name of the group
# \param:FILES files to add
# \param:GROUPS files to add
#
function(mo2_add_filter)
	cmake_parse_arguments(PARSE_ARGV 0 add_filter "" "NAME" "FILES;GROUPS")

	set(files ${add_filter_FILES})

	foreach(f ${add_filter_GROUPS})
		set(files ${files} ${f}.cpp ${f}.h ${f}.inc)
	endforeach()

	string(REPLACE "/" "\\" filter_name ${add_filter_NAME})
	source_group(${filter_name} FILES ${files})
endfunction()

#! mo2_find_qt_version : try to deduce Qt version from variables
#
function(mo2_find_qt_version VAR)

	if (DEFINED CACHE{${VAR}})
		return()
	endif()

	# TODO: deduce version from the QT_ROOT folder
	get_filename_component(VFOLDER ${QT_ROOT} DIRECTORY)
	get_filename_component(${VAR} ${VFOLDER} NAME)

	message(STATUS "deduced Qt version to ${${VAR}}")

	set(${VAR} ${${VAR}} CACHE STRING "Qt Version}")
endfunction()

#! mo2_deploy_qt : add commands to deploy Qt from the given binaries
#
# this function attach install() entries that deploy Qt for the given binaries
#
# \param:NOPLUGINS do not deploy Qt plugins
# \param:BINARIES names of the binaries (in the install path) to deploy from
#
function(mo2_deploy_qt)
	cmake_parse_arguments(DEPLOY "NOPLUGINS" "" "BINARIES" ${ARGN})

	# find_program() does not work for whatever reason, just going for the whole
	# name
	set(windeployqt ${QT_ROOT}/bin/windeployqt.exe)

	set(args
		"--no-translations \
		--verbose 0 \
		--webenginewidgets \
		--websockets \
		--libdir dlls \
		--no-compiler-runtime")

	if(${DEPLOY_NOPLUGINS})
		set(args "${args} --no-plugins")
	else()
		set(args "${args} --plugindir qtplugins")
	endif()

	set(bin "${CMAKE_INSTALL_PREFIX}/bin")

	set(deploys "")
	foreach(binary ${DEPLOY_BINARIES})
		set(deploys "${deploys}
			EXECUTE_PROCESS(
				COMMAND ${windeployqt} ${args} ${binary}
				WORKING_DIRECTORY \"${bin}\")")
	endforeach()

	install(CODE "
		${deploys}

		file(REMOVE_RECURSE \"${bin}/platforms\")
		file(REMOVE_RECURSE \"${bin}/styles\")
		file(REMOVE_RECURSE \"${bin}/dlls/imageformats\")
	")

	if(NOT ${DEPLOY_NOPLUGINS})
		install(CODE "
			file(RENAME \"${bin}/qtplugins/platforms\" \"${bin}/platforms\")
			file(RENAME \"${bin}/qtplugins/styles\" \"${bin}/styles\")
			file(RENAME \"${bin}/qtplugins/imageformats\" \"${bin}/dlls/imageformats\")
			file(REMOVE_RECURSE \"${bin}/qtplugins\")
		")
	endif()
endfunction()

set(MO2_UTILS_DEFINED TRUE)
