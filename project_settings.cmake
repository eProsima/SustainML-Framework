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
# This file sets settings for project sustainml_frontend
###############################################################################

set(MODULE_NAME
    sustainml_frontend)

set(MODULE_SUMMARY
    "Qt Application for SustainML.")

set(MODULE_CPP_VERSION 14)

set(MODULE_FIND_PACKAGES
        fastcdr
        fastrtps
        cpp_utils
        cmake_utils
        sustainml_cpp
    )

set (MODULE_VERSION_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")
