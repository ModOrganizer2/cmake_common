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

#! mo2_find_python_executable : find the full path to the Python executable
#
# \param:VARNAME name of the variable that will contain the path to Python
function(mo2_find_python_executable VARNAME)
	if (EXISTS "${PYTHON_ROOT}/PCbuild/amd64/python_d.exe")
		set(${VARNAME} "${PYTHON_ROOT}/PCbuild/amd64/python_d.exe" PARENT_SCOPE)
	else()
		set(${VARNAME} "${PYTHON_ROOT}/PCbuild/amd64/python.exe" PARENT_SCOPE)
	endif()
endfunction()

#! mo2_find_windeployqt_executable : find the full path to the windeployqt executable
#
# \param:VARNAME name of the variable that will contain the path to Python
function(mo2_find_windeployqt_executable VARNAME)
	# find_program() does not work for whatever reason, just going for the whole
	# name
	set(${VARNAME} ${QT_ROOT}/bin/windeployqt.exe PARENT_SCOPE)
endfunction()

#! mo2_set_project_to_run_from_install : set a target to run from a given executable
#
# this function is only meaningful for VS generator
#
# \param:TARGET name of the target
# \param:EXECUTABLE full path to the executable
# \param:WORKDIR working directory (optional, default is the directory of the executable)
#
function(mo2_set_project_to_run_from_install TARGET)
	cmake_parse_arguments(MO2 "" "EXECUTABLE;WORKDIR" "" ${ARGN})

    # extract directory
    if (NOT DEFINED MO2_WORKDIR)
        get_filename_component(MO2_WORKDIR ${MO2_EXECUTABLE} DIRECTORY)
    endif()

	set_target_properties(${TARGET} PROPERTIES
		VS_DEBUGGER_WORKING_DIRECTORY "${MO2_WORKDIR}"
		VS_DEBUGGER_COMMAND "${MO2_EXECUTABLE}")
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
# \param:GROUPS basename to add, e.g., "foo" will add "foo.cpp", "foo.h" and "foo.inc"
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

#! mo2_find_qt_version : try to deduce Qt version from QT_ROOT variable
#
# this function caches the given variable
#
# \param:VAR name of the variable to store the version into
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

#! mo2_deploy_qt_for_tests : add comments to deploy Qt for tests
#
# unlike mo2_deploy_qt(), this function does not perform any cleaning
#
# \param:TARGET name of the target to deploy for
# \param:BINARIES names of the binaries to deploy from
#
function(mo2_deploy_qt_for_tests)
	cmake_parse_arguments(DEPLOY "" "TARGET" "BINARIES" ${ARGN})

	mo2_find_windeployqt_executable(windeployqt)

	add_custom_command(TARGET "${DEPLOY_TARGET}"
		POST_BUILD
		COMMAND ${windeployqt}
		ARGS
			--dir $<TARGET_FILE_DIR:${DEPLOY_TARGET}>
			--no-translations
			--verbose 0
			--no-compiler-runtime
			"$<TARGET_FILE:${DEPLOY_TARGET}>"
			"${DEPLOY_BINARIES}"
		VERBATIM
		COMMAND_EXPAND_LISTS
		WORKING_DIRECTORY $<TARGET_FILE_DIR:${DEPLOY_TARGET}>
	)
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

	mo2_find_windeployqt_executable(windeployqt)

	set(args
		"--no-translations \
		--verbose 0 \
		--webenginewidgets \
		--websockets \
		--openglwidgets \
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
		file(REMOVE_RECURSE \"${bin}/dlls/tls\")
	")

	# === Begin Qt6 Fix ===

	# until there is a cleaner way to do this with windqtdeploy?

	# subfolder of QtQuick
	set(qt6_qtquick_to_remove "")
	list(APPEND qt6_qtquick_to_remove
		Controls Dialogs Layouts LocalStorage NativeStyle Particles Pdf Scene2D
		Scene3D Shapes Templates Timeline tooling VirtualKeyboard Window)

	set(qt6_qtdlls_to_remove "")
	list(APPEND qt6_qtdlls_to_remove
		3DAnimation 3DCore 3DExtras 3DInput 3DLogic 3DQuickScene2D 3DRender
		Pdf PdfQuick QmlLocalStorage QmlXmlListModel QuickControls2 QuickControls2Impl
		QuickDialogs2 QuickDialogs2QuickImpl QuickDialogs2Utils QuickLayouts QuickParticles
		QuickShapes QuickTemplates2 QuickTimeline Sql StateMachine StateMachineQml VirtualKeyboard)

	set(removals "")
	foreach (qt6_qtquick_removal ${qt6_qtquick_to_remove})
		set(removals "${removals}
			file(REMOVE_RECURSE \"${bin}/QtQuick/${qt6_qtquick_removal}\")")
	endforeach()
	foreach (qt6_dll_removal ${qt6_qtdlls_to_remove})
		set(removals "${removals}
			file(REMOVE \"${bin}/dlls/Qt6${qt6_dll_removal}.dll\")")
	endforeach()
	install(CODE "${removals}")

	# === End Qt6 Fix ===

	if(NOT ${DEPLOY_NOPLUGINS})
		install(CODE "
			file(RENAME \"${bin}/qtplugins/platforms\" \"${bin}/platforms\")
			file(RENAME \"${bin}/qtplugins/styles\" \"${bin}/styles\")
			file(RENAME \"${bin}/qtplugins/imageformats\" \"${bin}/dlls/imageformats\")
			file(RENAME \"${bin}/qtplugins/tls\" \"${bin}/dlls/tls\")
			file(REMOVE_RECURSE \"${bin}/qtplugins\")
		")
	endif()
endfunction()

#! mo2_add_lupdate : generate .ts files from the given sources
#
# this function adds a ${TARGET}_lupdate target
#
# \param:TARGET target to generate lupdate for
# \param:TS_FILE .ts file to generate
# \param:SOURCES source folders to generate .ts file from
#
function(mo2_add_lupdate TARGET)
	cmake_parse_arguments(MO2 "" "TS_FILE" "SOURCES" ${ARGN})

	set(translation_files "")
	set(ui_files "")

	get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)

	if ("CXX" IN_LIST languages)
		set(is_cpp True)
	else()
		set(is_cpp False)
	endif()

	# we glob the source files for Python plugins to avoid duplicate string in .ui and
	# .py, for C++, we will directly use MO2_SOURCES (using translation_files broke
	# the modorganizer build, probably because there are too many sources?)
	foreach (SOURCE ${MO2_SOURCES})
		if (${is_cpp})
			file(GLOB_RECURSE source_sources CONFIGURE_DEPENDS
				${SOURCE}/*.cpp
				${SOURCE}/*.h)
		else()
			file(GLOB_RECURSE source_sources CONFIGURE_DEPENDS
				${SOURCE}/*.py)
		endif()

		# ui files
		file(GLOB_RECURSE source_ui_files CONFIGURE_DEPENDS ${SOURCE}/*.ui)

		list(APPEND ui_files ${source_ui_files})
		list(APPEND translation_files ${source_sources} ${source_ui_files})
	endforeach()

	# for Python, we need to remove the .py generated because these can be generated
	# in the source folder
	list(TRANSFORM ui_files REPLACE "[.]ui$" ".py")
	list(REMOVE_ITEM translation_files ${ui_files})

	message(TRACE "TS_FILE: ${MO2_TS_FILE}, SOURCES: ${MO2_SOURCES}, FILES: ${translation_files}")

	if (${is_cpp})
		set(lupdate_command ${QT_ROOT}/bin/lupdate)
		set(lupdate_args ${MO2_SOURCES} -ts ${MO2_TS_FILE})
	else()
		mo2_find_python_executable(PYTHON_EXE)
		set(lupdate_command ${PYTHON_EXE})
		set(lupdate_args -I -m PyQt${QT_MAJOR_VERSION}.lupdate.pylupdate --ts "${MO2_TS_FILE}" ${translation_files})
	endif()

	add_custom_command(OUTPUT ${MO2_TS_FILE}
		COMMAND ${lupdate_command} ARGS ${lupdate_args}
		DEPENDS ${translation_files}
		VERBATIM)

	add_custom_target("${TARGET}_lupdate" DEPENDS ${MO2_TS_FILE})

	# we need to set this property otherwise there is an issue with C# projects
	# requiring nuget packages (e.g., installer_omod) that tries to resolve Nuget
	# packages on these target but fails because there are obviously none
	#
	# we also "hide" the target by moving them to autogen
	set_target_properties(${TARGET}_lupdate PROPERTIES
		VS_GLOBAL_ResolveNugetPackages False
		FOLDER autogen)

endfunction()

#! mo2_add_lrelease : generate .ts files from the given sources
#
# this function adds a ${TARGET}_lrelease target
#
# \param:TARGET target to generate releases for
# \param:INSTALL if set, QM files will be installed to bin/translations
# \param:QM_FILE .qm file to generate
# \param:TS_FILES source ts
#
function(mo2_add_lrelease TARGET)
	cmake_parse_arguments(MO2 "INSTALL" "QM_FILE" "TS_FILES" ${ARGN})

	add_custom_command(OUTPUT ${MO2_QM_FILE}
		COMMAND ${QT_ROOT}/bin/lrelease
		ARGS ${MO2_TS_FILES} -qm ${MO2_QM_FILE}
		DEPENDS "${MO2_TS_FILES}"
		VERBATIM)

	add_custom_target("${TARGET}_lrelease" DEPENDS ${MO2_QM_FILE})

	# we need to set this property otherwise there is an issue with C# projects
	# requiring nuget packages (e.g., installer_omod) that tries to resolve Nuget
	# packages on these target but fails because there are obviously none
	#
	# we also "hide" the target by moving them to autogen
	set_target_properties(${TARGET}_lrelease PROPERTIES
		VS_GLOBAL_ResolveNugetPackages False
		FOLDER autogen)

	if (${MO2_INSTALL})
		install(FILES ${MO2_QM_FILE} DESTINATION bin/translations)
	endif()

endfunction()


#! mo2_add_translations : generate translation files
#
# this function is a wrapper around mo2_add_lupdate and mo2_add_lrelease
#
# \param:TARGET target to generate translations for
# \param:RELEASE if set, will use mo2_add_lrelease to generate .qm files
# \param:INSTALL_RELEASE if true, will install generated .qm files (force RELEASE)
# \param:TS_FILE intermediate .ts file to generate
# \param:QM_FILE file .qm file to generate if RELEASE or INSTALL_RELEASE is set
# \param:SOURCES source directories to look for translations, send to mo2_add_lupdate
#
function(mo2_add_translations TARGET)
	cmake_parse_arguments(MO2 "RELEASE;INSTALL_RELEASE" "TS_FILE;QM_FILE" "SOURCES" ${ARGN})

	if (NOT MO2_TS_FILE)
		set(MO2_TS_FILE ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}_en.ts)
	endif()

	if (NOT MO2_QM_FILE)
		set(MO2_QM_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_en.qm)
	endif()

	# force release with install
	if (${MO2_INSTALL_RELEASE})
		set(MO2_RELEASE True)
	endif()

	mo2_add_lupdate(${TARGET} TS_FILE ${MO2_TS_FILE} SOURCES ${MO2_SOURCES})

	if (${MO2_RELEASE})
		mo2_add_lrelease(${TARGET}
			INSTALL ${MO2_INSTALL_RELEASE}
			TS_FILES ${MO2_TS_FILE}
			QM_FILE ${MO2_QM_FILE})

		add_dependencies(${TARGET}_lrelease ${TARGET}_lupdate)
		add_dependencies(${TARGET} ${TARGET}_lrelease)
	else()
		add_dependencies(${TARGET} ${TARGET}_lupdate)
	endif()

endfunction()

set(MO2_UTILS_DEFINED TRUE)
