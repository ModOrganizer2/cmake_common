cmake_minimum_required(VERSION 3.22)

if (DEFINED MO2_VERSIONS_INCLUDED)
	return()
endif()

if (CMAKE_CXX_COMPILER_LOADED)
	find_package(Qt6 CONFIG QUIET)
endif()

if (Qt6_FOUND)
	set(MO2_QT_VERSION_MAJOR ${Qt6_VERSION_MAJOR})
	set(MO2_QT_VERSION_MINOR ${Qt6_VERSION_MINOR})
	set(MO2_QT_VERSION_PATCH ${Qt6_VERSION_PATCH})
	set(MO2_QT_VERSION "${MO2_QT_VERSION_MAJOR}.${MO2_QT_VERSION_MINOR}.${MO2_QT_VERSION_PATCH}")
	message(STATUS "[MO2] Found Qt version: ${MO2_QT_VERSION}")
else()
	set(MO2_QT_VERSION_MAJOR 6)
	set(MO2_QT_VERSION_MINOR 7)
	set(MO2_QT_VERSION_PATCH 3)
	set(MO2_QT_VERSION "${MO2_QT_VERSION_MAJOR}.${MO2_QT_VERSION_MINOR}.${MO2_QT_VERSION_PATCH}")
	message(WARNING "Qt not found, assuming ${MO2_QT_VERSION}.")
endif()

set(MO2_PYTHON_VERSION "3.12")

# TODO: there is no prebuilt for 6.7.3, so we stay on 6.7.1 for now
set(MO2_PYQT_VERSION "6.7.1")
set(MO2_SIP_VERSION "6.8.6")

message(STATUS "[MO2] Python version: ${MO2_PYTHON_VERSION}")
message(STATUS "[MO2] PyQt version: ${MO2_PYQT_VERSION}")
message(STATUS "[MO2] SIP version: ${MO2_SIP_VERSION}")

# mark as included
set(MO2_VERSIONS_INCLUDED TRUE)
