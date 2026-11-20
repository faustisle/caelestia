find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND_CLIENT REQUIRED wayland-client)
find_program(WAYLAND_SCANNER wayland-scanner REQUIRED)

enable_language(C)

set(NIGHTLIGHT_PROTO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/protocols")
set(NIGHTLIGHT_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/protocols")
set(NIGHTLIGHT_PROTO "${NIGHTLIGHT_PROTO_DIR}/wlr-gamma-control-unstable-v1.xml")
set(NIGHTLIGHT_HEADER "${NIGHTLIGHT_GEN_DIR}/wlr-gamma-control-unstable-v1-client-protocol.h")
set(NIGHTLIGHT_CODE "${NIGHTLIGHT_GEN_DIR}/wlr-gamma-control-unstable-v1-protocol.c")

file(MAKE_DIRECTORY "${NIGHTLIGHT_GEN_DIR}")

add_custom_command(
    OUTPUT "${NIGHTLIGHT_HEADER}" "${NIGHTLIGHT_CODE}"
    COMMAND "${WAYLAND_SCANNER}" client-header "${NIGHTLIGHT_PROTO}" "${NIGHTLIGHT_HEADER}"
    COMMAND "${WAYLAND_SCANNER}" private-code "${NIGHTLIGHT_PROTO}" "${NIGHTLIGHT_CODE}"
    DEPENDS "${NIGHTLIGHT_PROTO}"
    VERBATIM
)

add_executable(caelestia-nightlight
    main.cpp
    "${NIGHTLIGHT_CODE}"
)

target_include_directories(caelestia-nightlight PRIVATE
    "${NIGHTLIGHT_GEN_DIR}"
    ${WAYLAND_CLIENT_INCLUDE_DIRS}
)

target_compile_definitions(caelestia-nightlight PRIVATE _GNU_SOURCE)
target_link_libraries(caelestia-nightlight PRIVATE ${WAYLAND_CLIENT_LIBRARIES})

install(TARGETS caelestia-nightlight RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
