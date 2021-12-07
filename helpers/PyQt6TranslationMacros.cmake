# This is a modified version of Qt6LinguistToolsMacros.cmake which calls
# pylupdate6 instead of lupdate, allowing Python strings to be extracted,
# too. It still requires the Qt version of the file to be included, but
# only this version of the function needs to be called. You also need to
# have PYTHON_ROOT set to a directory where a working pylupdate6.bat can
# be found. If you aren't using Windows, your platform's equivalent may
# work, too.

#=============================================================================
# Copyright 2005-2011 Kitware, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# * Neither the name of Kitware, Inc. nor the names of its
#   contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

include(CMakeParseArguments)

function(PYQT6_CREATE_TRANSLATION)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SRCFILES TSFILES OPTIONS)

    cmake_parse_arguments(_LUPDATE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    set(_source_files ${_LUPDATE_SRCFILES})
    set(_lupdate_options ${_LUPDATE_OPTIONS})
    set(_ts_files ${_LUPDATE_TSFILES})
    
    set(_ts_files_tagged "")

    foreach(_ts_file ${_ts_files})
        LIST(APPEND _ts_files_tagged "--ts")
        LIST(APPEND _ts_files_tagged ${_ts_file})
    endforeach()
    
    list(JOIN _ts_files " --ts " _ts_file_string)
    add_custom_command(TARGET "translations"
        COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
        ARGS -I -m PyQt6.lupdate.pylupdate ${_lupdate_options} ${_ts_files_tagged} ${_source_files}
        DEPENDS ${_source_files}
        WORKING_DIRECTORY ${PYTHON_ROOT}
        VERBATIM)
    set(${_qm_files} ${${_qm_files}} PARENT_SCOPE)
endfunction()
