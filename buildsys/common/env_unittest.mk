# DESCRIPTION:
#  Setup zSys environment variables for the UnitTest distribution.
#

export ZSYS_DISTRIBUTION=native

export ZSYS_TARGET=unittest

export ZSYS_ROOT=$(dirname $(dirname ${DIR}))
export ZSYS_ROOT=$(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST))))/../../)
export LD_LIBRARY_PATH=$(ZSYS_ROOT)/build/$(ZSYS_DISTRIBUTION)/$(ZSYS_TARGET)/lib

