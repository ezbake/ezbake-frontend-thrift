#!/bin/bash
#   Copyright (C) 2013-2014 Computer Sciences Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


[ -z $REQUIRED_THRIFT_VERSION ] && REQUIRED_THRIFT_VERSION='0.9.1'
[ -z $BUILD_DIR ]               && BUILD_DIR='target/generated-sources/thrift'

CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GENERATE_ARGS=("$@")
THRIFT_RESOURCE_DIR=${GENERATE_ARGS[0]}
THRIFT_INSTALLATION_PATH=${GENERATE_ARGS[1]:-/usr/local}
LANGUAGES_TO_GENERATE=(${GENERATE_ARGS[@]:2})

FINAL_DIR="src/main"
THRIFT_BINARY=${THRIFT_INSTALLATION_PATH}/bin/thrift
EZBAKE_BASE_THRIFT_DIR=${THRIFT_RESOURCE_DIR}/ezbake-base-thrift

echo ""
echo "Using thrift resource directory: ${THRIFT_RESOURCE_DIR}"
echo "Using thrift installation path: ${THRIFT_INSTALLATION_PATH}"
echo "Languages to generate: ${LANGUAGES_TO_GENERATE[*]}"


fail() {
    echo $@
    exit 1
}

function echo_and_execute_command()
{
    local cmd=$1
    echo ${cmd}
    ${cmd} || fail "Error in running: ${cmd}"
}


# Test to see if we have the required thrift installed
VERSION=$(${THRIFT_BINARY} -version 2>/dev/null | grep -F "${REQUIRED_THRIFT_VERSION}" |  wc -l)
if [ "$VERSION" -ne 1 ] ; then
    echo ">>>> thrift is not available"
    echo ">>>> expecting 'thrift -version' to return ${REQUIRED_THRIFT_VERSION}"
    fail ">>>> generated code will not be updated"
fi

#check if ezbake base thrift files were pulled from dependency
if [ ! -d "${EZBAKE_BASE_THRIFT_DIR}" ]; then
    fail ">>>> Unable to access ezbake base thrift directory - ${EZBAKE_BASE_THRIFT_DIR}"
fi


#create build directory
echo ""
echo_and_execute_command "rm -rf ${BUILD_DIR}"
echo_and_execute_command "mkdir -p ${BUILD_DIR}"
echo ""


#generate thrift source files to build directory
echo "GENERATING THRIFT SOURCE FILES"
EZREVERSE_PROXY_THRIFT_DIR="src/main/thrift"
EZBAKE_BASE_THRIFT_INC="-I ${EZBAKE_BASE_THRIFT_DIR}/src/main/thrift"
THRIFT_ARGS="${EZBAKE_BASE_THRIFT_INC} -I ${EZREVERSE_PROXY_THRIFT_DIR} -o $BUILD_DIR"


for i in $(seq 0 $((${#LANGUAGES_TO_GENERATE[@]} - 1))); do
    #java
    if [[ "java" == "${LANGUAGES_TO_GENERATE[$i]}" ]]; then
        echo " >> JAVA"
        for f in ${EZREVERSE_PROXY_THRIFT_DIR}/*.thrift; do
            echo_and_execute_command "${THRIFT_BINARY} ${THRIFT_ARGS} --gen java $f"
        done
        echo_and_execute_command "rm -rf ${FINAL_DIR}/java"
        echo_and_execute_command "cp -Rv ${BUILD_DIR}/gen-java ${FINAL_DIR}/java"
    fi

    #cpp
    if [[ "cpp" == "${LANGUAGES_TO_GENERATE[$i]}" ]]; then
        echo " >> CPP"
        for f in ${EZREVERSE_PROXY_THRIFT_DIR}/*.thrift; do
            echo_and_execute_command "${THRIFT_BINARY} ${THRIFT_ARGS} --gen cpp:cob_style $f"
        done
        DEST_DIR="${FINAL_DIR}/cpp"
        echo_and_execute_command "rm -rf ${DEST_DIR}"
        echo_and_execute_command "mkdir -p ${DEST_DIR}/include"

        for f in `find ${BUILD_DIR}/gen-cpp -name "*.cpp"`; do
            filename=${f##*/}
            if test "${filename#*skeleton}" != "${filename}"; then
                #do not include generated thrift .skeleton. files
                continue
            fi
            echo_and_execute_command "cp -fv $f ${DEST_DIR}"
        done

        for f in `find ${BUILD_DIR}/gen-cpp -name "*.h"`; do
            filename=${f##*/}
            echo_and_execute_command "cp -fv $f ${DEST_DIR}/include"
        done
    fi

    #python
    if [[ "python" == "${LANGUAGES_TO_GENERATE[$i]}" ]]; then
        echo " >> PYTHON"
        for f in ${EZREVERSE_PROXY_THRIFT_DIR}/*.thrift; do
            echo_and_execute_command "${THRIFT_BINARY} ${THRIFT_ARGS} -r --gen py:new_style $f"
        done
        echo_and_execute_command "rm -rf ${FINAL_DIR}/python"
        echo_and_execute_command "mkdir -p ${FINAL_DIR}/python"
        echo_and_execute_command "cp -Rv ${BUILD_DIR}/gen-py ${FINAL_DIR}/python/lib"
        echo_and_execute_command "${CUR_DIR}/generate_setup.py -p pom.xml -d ${FINAL_DIR}/python"
    fi

    #nodejs
    if [[ "nodejs" == "${LANGUAGES_TO_GENERATE[$i]}" ]]; then
        echo " >> NODEJS"
        for f in ${EZREVERSE_PROXY_THRIFT_DIR}/*.thrift; do
            echo_and_execute_command "${THRIFT_BINARY} ${THRIFT_ARGS} --gen js:node $f"
        done
        echo_and_execute_command "rm -rf ${FINAL_DIR}/nodejs"
        echo_and_execute_command "cp -Rv ${BUILD_DIR}/gen-nodejs ${FINAL_DIR}/nodejs"
    fi

    #ruby
    if [[ "ruby" == "${LANGUAGES_TO_GENERATE[$i]}" ]]; then
        echo " >> RUBY"
        for f in ${EZREVERSE_PROXY_THRIFT_DIR}/*.thrift; do
            echo_and_execute_command "${THRIFT_BINARY} ${THRIFT_ARGS} --gen rb $f"
        done
        echo_and_execute_command "rm -rf ${FINAL_DIR}/ruby"
        echo_and_execute_command "cp -Rv ${BUILD_DIR}/gen-rb ${FINAL_DIR}/ruby"
    fi
done

echo ">> DONE"
echo ""

