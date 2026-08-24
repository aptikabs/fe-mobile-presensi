cmake_minimum_required(VERSION 3.10.2)

project("native_security")

add_library(
        native_security
        SHARED
        native_security.cpp)

find_library(
        log-lib
        log)

target_link_libraries(
        native_security
        ${log-lib})
