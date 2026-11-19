cmake_minimum_required(VERSION 3.14)

include(toolchain.cmake)

project(picojpeg)

add_executable(picojpeg.elf)

target_sources(picojpeg.elf
    PRIVATE
    	src/init.S
        src/main.c
        src/picojpeg_test.c
        src/libpicojpeg.c
)

target_include_directories(picojpeg.elf
    PRIVATE
    PUBLIC
)

target_link_libraries(picojpeg.elf
    PRIVATE
    	-T "${CMAKE_CURRENT_SOURCE_DIR}/src/link.ld" -nostartfiles
        "${ExtraArchiveLibraries}"
        -Xlinker --no-warn-rwx-segments
        -Wl,--start-group -lc -lstdc++ -lgcc -lm -Wl,--end-group
)

# Create objdump from ELF.
set(objdump picojpeg.elf.objdump)
add_custom_command(
    OUTPUT "${objdump}"
    DEPENDS picojpeg.elf
    COMMAND "${ToolchainObjdump}" "${ToolchainObjdumpFlags}" picojpeg.elf >
            "${objdump}"
    COMMENT "Creating ${objdump}."
    VERBATIM
)
add_custom_target(create-objdump ALL DEPENDS "${objdump}")

enable_language(ASM)
enable_language(C)
enable_language(CXX)
