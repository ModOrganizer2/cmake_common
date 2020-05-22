cmake_minimum_required(VERSION 3.16)

function(set_project_to_run_from_install exec_name)
	set(vcxproj_user_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.vcxproj.user")

	if(NOT EXISTS ${vcxproj_user_file})
		file(WRITE ${vcxproj_user_file}
			"<?xml version=\"1.0\" encoding=\"utf-8\"?>
				<Project ToolsVersion=\"Current\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">
				  <PropertyGroup>
					<LocalDebuggerWorkingDirectory>${CMAKE_INSTALL_PREFIX}/bin</LocalDebuggerWorkingDirectory>
					<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>
					<LocalDebuggerCommand>${CMAKE_INSTALL_PREFIX}/bin/${exec_name}.exe</LocalDebuggerCommand>
				  </PropertyGroup>
				</Project>")
	endif()
endfunction()