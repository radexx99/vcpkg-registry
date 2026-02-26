set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_from_git(
  OUT_SOURCE_PATH
  SOURCE_PATH
  URL
  ssh://git@github.com/radexx99/matterfirpc.git
  REF
  15e599ec50e8345ee78f36bb4bcaa26fa730becb
  HEAD_REF
  nodeDeploy)

vcpkg_check_features(
  OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES
    deploy        MATTERFIRPC_ENABLE_DEPLOY
    privacy-cash  MATTERFIRPC_ENABLE_PRIVACY_CASH
)

if ("privacy-cash" IN_LIST FEATURES)
    message(STATUS "Privacy Cash feature enabled! Downloading Node.js...")

    # =====================================================================
    # 1. KONFIGURACJA WERSJI I SYSTEMU
    # =====================================================================
    set(NODE_VERSION "v20.19.0")

    if (VCPKG_TARGET_IS_WINDOWS)
        set(NODE_OS "win")
        set(NODE_EXT "zip")
        if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
            set(NODE_ARCH "arm64")
        else ()
            set(NODE_ARCH "x64")
        endif ()
        set(NODE_SHA512 "0") # <-- Tu jutro wkleisz hash dla Windowsa

    elseif (VCPKG_TARGET_IS_LINUX)
        set(NODE_OS "linux")
        set(NODE_EXT "tar.xz")
        if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
            set(NODE_ARCH "arm64")
        else ()
            set(NODE_ARCH "x64")
        endif ()
        set(NODE_SHA512 "0") # <-- Tu jutro wkleisz hash dla Linuksa

    elseif (VCPKG_TARGET_IS_OSX)
        set(NODE_OS "darwin")
        set(NODE_EXT "tar.gz") # macOS używa tar.gz!
        if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
            set(NODE_ARCH "arm64")
            set(NODE_SHA512 "0") # <-- Tu jutro wkleisz hash dla Maca (M1/M2/M3)
        else ()
            set(NODE_ARCH "x64")
            set(NODE_SHA512 "0") # <-- Tu jutro wkleisz hash dla Maca (Intel)
        endif ()

    else ()
        message(FATAL_ERROR "Unsupported OS for Node.js embedding in vcpkg")
    endif ()

    # =====================================================================
    # 2. POBIERANIE NODE.JS PRZEZ VCPKG (Bypass izolacji sieciowej)
    # =====================================================================
    set(NODE_DIR_NAME "node-${NODE_VERSION}-${NODE_OS}-${NODE_ARCH}")
    set(NODE_FILENAME "${NODE_DIR_NAME}.${NODE_EXT}")
    set(NODE_URL "https://nodejs.org/dist/${NODE_VERSION}/${NODE_FILENAME}")

    vcpkg_download_distfile(NODE_ARCHIVE
            URLS "${NODE_URL}"
            FILENAME "${NODE_FILENAME}"
            SHA512 ${NODE_SHA512}
    )

    # =====================================================================
    # 3. WYPAKOWANIE DO FOLDERU TYMCZASOWEGO
    # =====================================================================
    vcpkg_extract_source_archive(
            NODE_EXTRACTED_DIR
            ARCHIVE "${NODE_ARCHIVE}"
            SOURCE_BASE "${NODE_DIR_NAME}"
    )

    # Definiujemy ścieżki do plików wykonywalnych, żeby podać je do CMake
    if (VCPKG_TARGET_IS_WINDOWS)
        set(VCPKG_NODE_EXE "${NODE_EXTRACTED_DIR}/node.exe")
        set(VCPKG_NPM_EXE "${NODE_EXTRACTED_DIR}/npm.cmd")
    else ()
        set(VCPKG_NODE_EXE "${NODE_EXTRACTED_DIR}/bin/node")
        set(VCPKG_NPM_EXE "${NODE_EXTRACTED_DIR}/bin/npm")
    endif ()

    # Genialny ruch: Dorzucamy ścieżki do listy opcji TYLKO tutaj!
    list(APPEND FEATURE_OPTIONS
            "-DUSER_NODE_EXE=${VCPKG_NODE_EXE}"
            "-DUSER_NPM_EXE=${VCPKG_NPM_EXE}"
    )
else()
    message(STATUS "Privacy Cash feature disabled. Skipping Node.js download.")
endif()

vcpkg_cmake_configure(
  SOURCE_PATH
  "${SOURCE_PATH}"
  OPTIONS
  -DMATTERFIRPC_BUILD_TESTS=OFF
  -DMATTERFIRPC_PEDANTIC_BUILD=OFF
  ${FEATURE_OPTIONS}
  OPTIONS_RELEASE
  -DMATTERFIRPC_DEBUG_BUILD=OFF
  -DMATTERFIRPC_INSTALL_LICENSE=ON
  -DMATTERFIRPC_LICENSE_FILE_NAME=copyright
  OPTIONS_DEBUG
  -DMATTERFIRPC_DEBUG_BUILD=ON
  -DMATTERFIRPC_INSTALL_HEADERS=OFF
  -DMATTERFIRPC_INSTALL_LICENSE=OFF
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
  PACKAGE_NAME
  "MatterFiRPC"
  NO_PREFIX_CORRECTION
)

file(
  INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
