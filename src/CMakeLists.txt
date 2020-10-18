set(plasmaphonedialer_SRCS
    main.cpp
    dialerutils.cpp
    call-handler.cpp
    callhistorymodel.cpp
    call-manager.cpp
    qpulseaudioengine.cpp
)
add_executable(plasmaphonedialer ${plasmaphonedialer_SRCS})
target_compile_definitions(plasmaphonedialer PRIVATE -DPROJECT_VERSION="${PROJECT_VERSION}")

find_package(PhoneNumber COMPONENTS PhoneNumber REQUIRED)

target_link_libraries(plasmaphonedialer
 PhoneNumber::PhoneNumber
 Qt5::Quick
 Qt5::Sql
 KF5::CoreAddons
 KF5::I18n
 KF5::DBusAddons
 KF5::Notifications
 TelepathyQt5::Core 
 ${PULSEAUDIO_LIBRARY}
 ${PULSEAUDIO_MAINLOOP_LIBRARY}
)

if(EMBED_QML_FILES)
    target_sources(plasmaphonedialer PRIVATE
        resources.qrc
    )
else()
    target_compile_definitions(plasmaphonedialer PRIVATE
        QML_PATH="${KDE_INSTALL_FULL_DATAROOTDIR}/${PROJECT_NAME}"
    )
    install(DIRECTORY "qml/" DESTINATION ${KDE_INSTALL_DATAROOTDIR}/${PROJECT_NAME})
endif()

install(TARGETS plasmaphonedialer ${INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES plasma_dialer.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFY5RCDIR})

configure_file(org.freedesktop.Telepathy.Client.Plasma.Dialer.service.in
                org.freedesktop.Telepathy.Client.Plasma.Dialer.service)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.freedesktop.Telepathy.Client.Plasma.Dialer.service
        DESTINATION ${DBUS_SERVICES_INSTALL_DIR})

install(FILES Plasma.Dialer.client DESTINATION ${SHARE_INSTALL_PREFIX}/telepathy/clients/)
