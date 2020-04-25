include(${CMAKE_CURRENT_LIST_DIR}/helpers/PyQt5TranslationMacros.cmake)

macro(do_python_project)
	find_package(Qt5LinguistTools)

	if(${create_translations})
		pyqt5_create_translation(
			qm_files
			${CMAKE_SOURCE_DIR}/src ${additional_translations}
			${CMAKE_SOURCE_DIR}/src/${CMAKE_PROJECT_NAME}_en.ts
		)
	endif()

	file(GLOB_RECURSE source_files CONFIGURE_DEPENDS *.py)

	set(input_files
		${source_files}
		${qm_files})
endmacro()
