# Copyright 2024 Proyectos y Sistemas de Mantenimiento SL (eProsima).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
# CMake build rules for SustainML Front-end
###############################################################################
cmake_minimum_required(VERSION 3.5)
cmake_policy(VERSION 3.5...3.13)

# Done this to set machine architecture and be able to call cmake_utils
enable_language(CXX)

###############################################################################
# Find package cmake_utils
###############################################################################
# Package cmake_utils is required to get every cmake macro needed
find_package(cmake_utils REQUIRED)

###############################################################################
# Project
###############################################################################
# Configure project by info set in project_settings.cmake
# - Load project_settings variables
# - Read version
# - Set installation paths
configure_project()

# Call explictly project
project(
    ${MODULE_NAME}
    VERSION
        ${MODULE_VERSION}
    DESCRIPTION
        ${MODULE_DESCRIPTION}
    LANGUAGES
        CXX
)

###############################################################################
# C++ Project
###############################################################################
# Configure CPP project for dependencies and required flags:
# - Set CMake Build Type
# - Set C++ version
# - Set shared libraries by default
# - Find external packages and thirdparties
# - Activate Code coverage if flag CODE_COVERAGE
# - Activate Address sanitizer if flag ASAN_BUILD
# - Configure log depending on LOG_INFO flag and CMake type
configure_project_cpp()

###############################################################################
# Load Qt projects
###############################################################################
set(QT_PATH "" CACHE STRING "Path to the Qt installation folder")
list(APPEND CMAKE_PREFIX_PATH ${QT_PATH})

find_package(Qt5 5.15 COMPONENTS Core Widgets Gui Qml Quick Charts QuickControls2 REQUIRED)

foreach(component Core Widgets Gui Quick Qml QuickControls2 Utils)
    if(${Qt5${component}_FOUND})
        message(STATUS "Found Qt5${component}: ${Qt5${component}_CONFIG} (found version ${Qt5${component}_VERSION})")
    endif()
endforeach()

###############################################################################
# Qt compiler flags, pthreads, and position independent code (PIE)
###############################################################################
if(MSVC OR MSVC_IDE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${Qt5Widgets_EXECUTABLE_COMPILE_FLAGS}")
else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${Qt5Widgets_EXECUTABLE_COMPILE_FLAGS} -pthread -no-pie")
endif()

###############################################################################
# Configure Qt project
###############################################################################
# Include the Qt5Widgets and QtQml header files for the Qt Framework and QML functions.
include_directories(${Qt5Widgets_INCLUDE_DIRS} ${QtQml_INCLUDE_DIRS})
# Specify the needed Qt definitions
add_definitions(${Qt5Widgets_DEFINITIONS} ${QtQml_DEFINITIONS} ${Qt5Quick_DEFINITIONS})

# WARNING
# The creation of the qml_qrc.cpp file is managed by the rcc
# If this functionality is called from the main cmake dir (this) the file will be generated in building time
# Thus, if this file is required in subdirectories, this 4 instructions below must be added in the same
# CMakeList of the executable (Use different name for QT_RESOURCES variable)

# Set the app icon resource file for windows
#set(APP_ICON_RESOURCE_WINDOWS ${CMAKE_CURRENT_SOURCE_DIR}/resources/sustainml_frontend.rc)

# Set the qml.qrc file containing the QML and other resources of the application
qt5_add_resources(QT_RESOURCES
        ${PROJECT_SOURCE_DIR}/src/qml.qrc
        ${PROJECT_SOURCE_DIR}/src/font.qrc
        ${PROJECT_SOURCE_DIR}/src/images.qrc)

# Additional compilation steps required by a Qt program
# User Interface Compiler (UIC)
set(CMAKE_AUTOUIC ON)
# Meta-Object Compiler (MOC)
set(CMAKE_AUTOMOC ON)
# Resource Compiler (RCC)
set(CMAKE_AUTORCC ON)

###############################################################################
# Compile C++ library
###############################################################################
set(PROJECT_INLCUDE_DIRS
    "${PROJECT_SOURCE_DIR}/include")

file(GLOB_RECURSE PROJECT_SOURCE_FILES
    "${PROJECT_SOURCE_DIR}/src/main.cpp"
    "${PROJECT_SOURCE_DIR}/src/cpp/*.c"
    "${PROJECT_SOURCE_DIR}/src/cpp/*.cpp"
    "${PROJECT_SOURCE_DIR}/src/cpp/*.cxx"
    "${PROJECT_SOURCE_DIR}/src/cpp/**/*.c"
    "${PROJECT_SOURCE_DIR}/src/cpp/**/*.cpp"
    "${PROJECT_SOURCE_DIR}/src/cpp/**/*.cxx")

file(GLOB_RECURSE PROJECT_HEADER_FILES
    "${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}/*.h"
    "${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}/*.hpp"
    "${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}/**/*.h"
    "${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME}/**/*.hpp")

set(EXECUTABLE_REQUIRED_FILES ${PROJECT_SOURCE_FILES} ${PROJECT_HEADER_FILES} ${QT_RESOURCES})

compile_tool(
    "${PROJECT_SOURCE_DIR}/src" # Source directory
    "${EXECUTABLE_REQUIRED_FILES}"
    "${PROJECT_INLCUDE_DIRS}"
)

###############################################################################
# Disable QDebug traces in Release
###############################################################################
target_compile_definitions(${PROJECT_NAME} PRIVATE
    $<$<NOT:$<STREQUAL:"${CMAKE_BUILD_TYPE}","Debug">>:QT_NO_DEBUG_OUTPUT>)

###############################################################################
# Packaging
###############################################################################
eprosima_packaging()
