cmake_minimum_required(VERSION 3.16)

#! mo2_configure_extension : configure a MO2 extension
#
# this function read the extension identifier from the metadata.json file and
# expose it as a ${extension_identifier} variable
#
# this function also trigger the installation of the metadata file to the
# extension directory
#
function(mo2_configure_extension)
    set(METADATA_FILE ${CMAKE_CURRENT_SOURCE_DIR}/metadata.json)

    if(NOT (EXISTS ${METADATA_FILE}))
        message(ERROR "metadata file ${METADATA_FILE} not found")
    endif()

    file(READ ${METADATA_FILE} JSON_METADATA)
    string(JSON extension_identifier GET ${JSON_METADATA} id)
    string(JSON extension_icon ERROR_VARIABLE extension_icon_error GET ${JSON_METADATA} icon)

    set(MO2_EXTENSION_ID ${extension_identifier} PARENT_SCOPE)
    install(FILES ${METADATA_FILE}
        DESTINATION ${MO2_INSTALL_BIN}/extensions/${extension_identifier}/)

    if (NOT ${extension_icon} MATCHES  "icon-NOTFOUND")
        install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/${extension_icon}
            DESTINATION ${MO2_INSTALL_BIN}/extensions/${extension_identifier}/)
    endif()

endfunction()
