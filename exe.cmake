cmake_minimum_required(VERSION 3.16)

function(set_project_to_run_from_install)
	set(vcxproj_user_file "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.vcxproj.user")
	get_target_property(output_name ${CMAKE_PROJECT_NAME} OUTPUT_NAME)

	if(NOT EXISTS ${vcxproj_user_file})
		file(WRITE ${vcxproj_user_file}
			"<?xml version=\"1.0\" encoding=\"utf-8\"?>
				<Project ToolsVersion=\"Current\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">
				  <PropertyGroup>
					<LocalDebuggerWorkingDirectory>${CMAKE_INSTALL_PREFIX}/bin</LocalDebuggerWorkingDirectory>
					<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>
					<LocalDebuggerCommand>${CMAKE_INSTALL_PREFIX}/bin/${output_name}.exe</LocalDebuggerCommand>
				  </PropertyGroup>
				</Project>")
	endif()
endfunction()


function(deploy_qt)
	cmake_parse_arguments(PARSE_ARGV 0 deploy_qt "" "" "BINARIES")

	set(qt5bin ${Qt5Core_DIR}/../../../bin)
	find_program(WINDEPLOYQT_COMMAND windeployqt PATHS ${qt5bin} NO_DEFAULT_PATH)

	set(args
		"--no-translations \
		--plugindir qtplugins \
		--verbose 0 \
		--webenginewidgets \
		--websockets \
		--libdir dlls \
		--no-compiler-runtime")

	set(bin "${CMAKE_INSTALL_PREFIX}/bin")

	set(deploys "")
	foreach(binary ${deploy_qt_BINARIES})
		set(deploys "${deploys}
			EXECUTE_PROCESS(
				COMMAND ${qt5bin}/windeployqt.exe ${args} ${binary}
				WORKING_DIRECTORY ${bin})")
	endforeach()

	install(CODE "
		${deploys}

		file(REMOVE_RECURSE ${bin}/platforms)
		file(REMOVE_RECURSE ${bin}/styles)
		file(REMOVE_RECURSE ${bin}/dlls/imageformats)
		file(RENAME ${bin}/qtplugins/platforms ${bin}/platforms)
		file(RENAME ${bin}/qtplugins/styles ${bin}/styles)
		file(RENAME ${bin}/qtplugins/imageformats ${bin}/dlls/imageformats)
		file(REMOVE_RECURSE ${bin}/qtplugins)
	")
endfunction()


add_executable(${CMAKE_PROJECT_NAME} WIN32 ${input_files})
set_project_to_run_from_install()

if(DEFINED executable_name)
	set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
		OUTPUT_NAME ${executable_name})
endif()

install(TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION bin)
install(FILES $<TARGET_PDB_FILE:${CMAKE_PROJECT_NAME}> DESTINATION pdb)
