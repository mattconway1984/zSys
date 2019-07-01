# DESCRIPTION:
#   All the global variables used by the zSys buildsystem should be defined 
#   and set in this file
#

# Variables to setup paths to the various *important* directories
ZSYS_BUILD_ROOT=${ZSYS_ROOT}/build/${ZSYS_DISTRIBUTION}/${ZSYS_TARGET}
ZSYS_SHARED_LIBS_PATH=$(ZSYS_BUILD_ROOT)/lib
ZSYS_SHARED_INCS_PATH=$(ZSYS_BUILD_ROOT)/inc
ZSYS_SHARED_BINS_PATH=$(ZSYS_BUILD_ROOT)/bin

# Variables used to find what components and libraries exist
ZSYS_ALL_COMPONENTS = $(patsubst ${ZSYS_ROOT}/components/%/,%,$(sort $(dir $(wildcard ${ZSYS_ROOT}/components/*/))))
ZSYS_ALL_LIBRARIES = $(patsubst ${ZSYS_ROOT}/libraries/%/,%,$(sort $(dir $(wildcard ${ZSYS_ROOT}/libraries/*/))))

# Variables used to configure Doxygen
ZSYS_DOXYGEN_PATH=${ZSYS_ROOT}/build/docs 
ZSYS_DOXYGEN_CONFIG_FILE=${ZSYS_ROOT}/buildsys/tools/doxygen/doxy.conf
ZSYS_DOXYGEN_CONFIG_BACKUP=${ZSYS_ROOT}/buildsys/tools/doxygen/doxy.conf.bak

# When running CMOCK a prefix text can be supplied, which is set to be:
CMOCK_PREFIX=mock_

