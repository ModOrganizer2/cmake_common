cmake_minimum_required(VERSION 3.16)

function(set_project_to_run_from_install)
	set(vcxproj_user_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.vcxproj.user")

	get_target_property(output_name ${PROJECT_NAME} OUTPUT_NAME)
	if("${output_name}" STREQUAL "output_name-NOTFOUND")
		set(output_name ${PROJECT_NAME})
	endif()

	if(NOT EXISTS ${vcxproj_user_file})
		file(WRITE ${vcxproj_user_file}
			"<?xml version=\"1.0\" encoding=\"utf-8\"?>
				<Project ToolsVersion=\"Current\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">
				  <PropertyGroup>
					<LocalDebuggerWorkingDirectory>${CMAKE_INSTALL_PREFIX}/bin</LocalDebuggerWorkingDirectory>
					<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>
					<LocalDebuggerCommand>${CMAKE_INSTALL_PREFIX}/bin/ModOrganizer.exe</LocalDebuggerCommand>
				  </PropertyGroup>
				</Project>")
	endif()
endfunction()