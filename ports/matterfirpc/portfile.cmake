set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_from_git(
  OUT_SOURCE_PATH
  SOURCE_PATH
  URL
  ssh://git@github.com/radexx99/matterfirpc.git
  REF
  96721a777a8b5476b5dfeaf7768a36d3f72201fa
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
    # 1. CONFIGURING NODE.js
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
        set(NODE_SHA512 "7cb2f6b2f4cbcb2cef3d2f3089f65c1a570bc274d8a5c98fbbe53e352eb8acdf88ca4d4de7bcbb8abcd9599bc6fefa4e950ba46851cf7e87215c6b4f4a627a7c")

    elseif (VCPKG_TARGET_IS_LINUX)
        set(NODE_OS "linux")
        set(NODE_EXT "tar.xz")
        if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
            set(NODE_ARCH "arm64")
        else ()
            set(NODE_ARCH "x64")
        endif ()
        set(NODE_SHA512 "125d3e73d3e07fe2b7467f33cb69b21f8a551d018ef2b2d74bf2395c2ac986eae31b58beff56f68965b0d241b39f426499fd78ca9e15f043d2d6bc46b7175f7a")

    elseif (VCPKG_TARGET_IS_OSX)
        set(NODE_OS "darwin")
        set(NODE_EXT "tar.gz")
        if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
            set(NODE_ARCH "arm64")
            set(NODE_SHA512 "cecadbc9488ae1dad39183248b0122aa23d63ea044eb4f795f5689c375f5dd17628cdd6db7bc100c9e07a4f20c78a33c16741cc8ab39c6ecc6d1100b599847c4")
        else ()
            set(NODE_ARCH "x64")
            set(NODE_SHA512 "a0baa74c645c7da3cd971ee4cd5c38413d7d56a989429d3cac6b5e4cb8feb3da7e8a2b83152c5233a539ce285da6541822c5e4bcc544c0bb6119a53b6d9fff50")
        endif ()

    else ()
        message(FATAL_ERROR "Unsupported OS for Node.js embedding in vcpkg")
    endif ()

    # =====================================================================
    # 2. DOWNLOADING NODEJS ARCHIVE // VCPKG IS BULLETPROOF with that
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
    # 3. Extract
    # =====================================================================
    # =====================================================================
    # Extract to a temporary folder
    # =====================================================================
    vcpkg_extract_source_archive(
            NODE_EXTRACTED_DIR
            ARCHIVE "${NODE_ARCHIVE}"
            SOURCE_BASE "${NODE_DIR_NAME}"
    )

    if(VCPKG_TARGET_IS_WINDOWS)
        set(VCPKG_NODE_EXE "${NODE_EXTRACTED_DIR}/node.exe")
        set(VCPKG_NPM_JS_PATH "${NODE_EXTRACTED_DIR}/node_modules/npm/bin/npm-cli.js")
    else()
        set(VCPKG_NODE_EXE "${NODE_EXTRACTED_DIR}/bin/node")
        set(VCPKG_NPM_JS_PATH "${NODE_EXTRACTED_DIR}/lib/node_modules/npm/bin/npm-cli.js")
    endif()

    # =====================================================================
    # Inject paths into CMake
    # We omit USER_NPM_EXE completely because Bulletproof Mode only needs
    # the raw JS script and the Node executable.
    # =====================================================================
    list(APPEND FEATURE_OPTIONS
            "-DUSER_NODE_EXE=${VCPKG_NODE_EXE}"
            "-DUSER_NPM_JS_PATH=${VCPKG_NPM_JS_PATH}"
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
