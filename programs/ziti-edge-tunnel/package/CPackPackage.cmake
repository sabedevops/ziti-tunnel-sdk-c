set(CPACK_INSTALL_CMAKE_PROJECTS "${CMAKE_CURRENT_BINARY_DIR};${PROJECT_NAME};${PROJECT_NAME};/")

# this cmake file included if Linux
find_program(LSB_RELEASE_EXEC lsb_release)
execute_process(COMMAND ${LSB_RELEASE_EXEC} -is OUTPUT_VARIABLE LSB_RELEASE_ID_SHORT OUTPUT_STRIP_TRAILING_WHITESPACE)
if(LSB_RELEASE_ID_SHORT MATCHES "^(Debian|Ubuntu|Mint|Pop)$")
	set(CPACK_GENERATOR "DEB")
elseif(LSB_RELEASE_ID_SHORT MATCHES "^(RedHat|Rocky|CentOS|Fedora)$")
	set(CPACK_GENERATOR "RPM")
else()
	message(FATAL_ERROR "failed to match LSB release name: ${LSB_RELEASE_ID_SHORT}")
endif()

set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_CURRENT_SOURCE_DIR}/package/CPackGenConfig.cmake)

set(CPACK_PACKAGE_CONTACT "support@netfoundry.io")
set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set(CPACK_PACKAGE_RELEASE 1)
set(CPACK_PACKAGE_VENDOR "NetFoundry")
set(CPACK_PACKAGE_VERSION ${ver})
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_PACKAGE_RELEASE}")

set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/ziti")
set(CPACK_BIN_DIR "${CPACK_PACKAGING_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}")
set(CPACK_ETC_DIR "${CPACK_PACKAGING_INSTALL_PREFIX}/${CMAKE_INSTALL_SYSCONFDIR}")
set(CPACK_SHARE_DIR "${CPACK_PACKAGING_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")

set(INSTALL_IN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/package")
set(INSTALL_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/package")

set(ZITI_IDENTITY_DIR "${CPACK_ETC_DIR}/identity")

set(SYSTEMD_SERVICE_NAME "${CPACK_PACKAGE_NAME}")
set(SYSTEMD_UNIT_FILE_NAME "${SYSTEMD_SERVICE_NAME}.service")
set(SYSTEMD_EXECSTARTPRE "${INSTALL_OUT_DIR}/${SYSTEMD_SERVICE_NAME}.sh")
set(SYSTEMD_ENV_FILE "${INSTALL_OUT_DIR}/${SYSTEMD_SERVICE_NAME}.env")

configure_file("${INSTALL_IN_DIR}/${SYSTEMD_UNIT_FILE_NAME}.in" 
	       "${INSTALL_OUT_DIR}/${SYSTEMD_UNIT_FILE_NAME}"
	       @ONLY)
install(FILES "${INSTALL_OUT_DIR}/${SYSTEMD_UNIT_FILE_NAME}"
	DESTINATION "${CPACK_SHARE_DIR}"
	COMPONENT "${PROJECT_NAME}")

configure_file("${INSTALL_IN_DIR}/ziti-edge-tunnel.sh.in" "${SYSTEMD_EXECSTARTPRE}" @ONLY)
install(FILES "${SYSTEMD_EXECSTARTPRE}"
	DESTINATION "${CPACK_BIN_DIR}"
	PERMISSIONS 
	    OWNER_READ OWNER_WRITE OWNER_EXECUTE 
	    GROUP_READ GROUP_EXECUTE 
	    WORLD_READ WORLD_EXECUTE
	COMPONENT "${PROJECT_NAME}")

set(RPM_POST_INSTALL_IN "${INSTALL_IN_DIR}/post.sh.in")
set(RPM_PRE_UNINSTALL_IN "${INSTALL_IN_DIR}/preun.sh.in")
set(RPM_POST_UNINSTALL_IN "${INSTALL_IN_DIR}/postun.sh.in")

set(CPACK_RPM_POST_INSTALL "${INSTALL_OUT_DIR}/post.sh")
set(CPACK_RPM_PRE_UNINSTALL "${INSTALL_OUT_DIR}/preun.sh")
set(CPACK_RPM_POST_UNINSTALL "${INSTALL_OUT_DIR}/postun.sh")

configure_file("${RPM_POST_INSTALL_IN}" "${CPACK_RPM_POST_INSTALL}" @ONLY)
configure_file("${RPM_PRE_UNINSTALL_IN}" "${CPACK_RPM_PRE_UNINSTALL}" @ONLY)
configure_file("${RPM_POST_UNINSTALL_IN}" "${CPACK_RPM_POST_UNINSTALL}" @ONLY) 

set(DEB_CONFFILES_IN "${INSTALL_IN_DIR}/conffiles.in")
set(DEB_POST_INSTALL_IN "${INSTALL_IN_DIR}/postinst.in")
set(DEB_PRE_UNINSTALL_IN "${INSTALL_IN_DIR}/prerm.in")
set(DEB_POST_UNINSTALL_IN "${INSTALL_IN_DIR}/postrm.in")

set(CPACK_DEB_CONFFILES "${INSTALL_OUT_DIR}/conffiles")
set(CPACK_DEB_POST_INSTALL "${INSTALL_OUT_DIR}/postinst")
set(CPACK_DEB_PRE_UNINSTALL "${INSTALL_OUT_DIR}/prerm")
set(CPACK_DEB_POST_UNINSTALL "${INSTALL_OUT_DIR}/postrm")

configure_file("${DEB_CONFFILES_IN}" "${DEB_CONFFILES}" @ONLY)
configure_file("${DEB_POST_INSTALL_IN}" "${CPACK_DEB_POST_INSTALL}" @ONLY)
configure_file("${DEB_PRE_UNINSTALL_IN}" "${CPACK_DEB_PRE_UNINSTALL}" @ONLY)
configure_file("${DEB_POST_UNINSTALL_IN}" "${CPACK_DEB_POST_UNINSTALL}" @ONLY)

install(DIRECTORY DESTINATION "${CPACK_ETC_DIR}" COMPONENT "${PROJECT_NAME}")
install(DIRECTORY DESTINATION "${ZITI_IDENTITY_DIR}" COMPONENT "${PROJECT_NAME}")

configure_file("${INSTALL_IN_DIR}/systemd_env.in" "${SYSTEMD_ENV_FILE}")
install(FILES "${SYSTEMD_ENV_FILE}"
	DESTINATION "${CPACK_ETC_DIR}"
	COMPONENT "${PROJECT_NAME}")
