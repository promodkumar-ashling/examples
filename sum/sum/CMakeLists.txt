cmake_minimum_required(VERSION 3.14)

include(toolchain.cmake)

project(sum)

add_executable(sum.elf)

target_sources(sum.elf
    PRIVATE
        src/startup.S
        src/main.c
)

target_link_libraries(sum.elf
    PRIVATE
        -T "${CMAKE_CURRENT_SOURCE_DIR}/src/link.ld"
        -nostartfiles
        -Xlinker --gc-sections
)

enable_language(ASM)
enable_language(C)
