set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR "General")
set(CMAKE_CROSSCOMPILING True)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Defaulting build type to Debug.")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build." FORCE)
endif()

set(CMAKE_C_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_ASM_FLAGS_DEBUG "-g3")
set(CMAKE_C_FLAGS_RELEASE "-O2")

# MIPS RISC-V core: RV64IMA (riscv64-mti-elf, MIPS GNU Tools)
add_compile_options(
    -march=rv64ima -mabi=lp64 -mcmodel=medany
    -mno-ext -mno-ins
    -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections
)

add_link_options(
    -march=rv64ima -mabi=lp64 -mcmodel=medany
)

add_compile_definitions(
    
)
