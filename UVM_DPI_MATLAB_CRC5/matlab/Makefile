CUR_DIR_PATH := $(shell echo $(CURDIR))

all:create_folder matlab_gen gen_lib

# filename
FOLDER_NAME := output

# src_cpp
#cpp := src_cpp
cpp := crc_src_cpp
# Check if the folder exists
ifeq ($(wildcard $(FOLDER_NAME)),)
# If the folder does not exist, create a folder
create_folder:
	@echo "Creating $(FOLDER_NAME) folder"
	mkdir -p $(FOLDER_NAME)
else
# If the folder already exists, no action will be taken
create_folder:
	@echo "$(FOLDER_NAME) folder already exists"
endif

# default target
.PHONY: default
default: create_folder


matlab_gen:
	${MATLAB_HOME}/bin/mcc -W cpplib:libcrc5_calc crc5_calc.m  -g -d output/

gen_lib:
	g++ -shared -fPIC -g -Wno-write-strings \
	-Ioutput -I${VCS_HOME}/include -Icrc_src_cpp -I${MATLAB_HOME}/extern/include \
	-lmwmclmcrrt -L${MATLAB_HOME}/runtime/glnxa64 \
	-lcrc5_calc -Loutput \
	-Wl,-rpath=${CUR_DIR_PATH} -Wl,-rpath=${CUR_DIR_PATH}/output \
	./crc_src_cpp/CRC5_common.cpp \
	./crc_src_cpp/CRC5_dpi.cpp \
	-o libcrc5_calc_sim.so

clean:
	-rm -rf output *.so
