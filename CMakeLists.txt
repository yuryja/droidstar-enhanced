cmake_minimum_required(VERSION 3.16)
if(POLICY CMP0072)
  cmake_policy(SET CMP0072 NEW)
endif()
project(DroidStar VERSION 1.0 LANGUAGES C CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

if(IOS)
    find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Multimedia Network Quick QuickControls2)
else()
    find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Multimedia Network Quick QuickControls2 SerialPort)
endif()

qt_standard_project_setup(REQUIRES 6.5)

set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/droidstar.rc")
set(MACOSX_BUNDLE_ICON_FILE droidstar.icns)
set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/images/droidstar.icns")
set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

qt_add_executable(DroidStar WIN32 MACOSX_BUNDLE
    core/CRCenc.cpp
    core/CRCenc.h
    core/DMRDefines.h
    core/Golay24128.cpp
    core/Golay24128.h
    core/M17Convolution.cpp
    core/M17Convolution.h
    core/M17Defines.h
    core/MMDVMDefines.h
    core/SHA256.cpp
    core/SHA256.h
    core/YSFConvolution.cpp
    core/YSFConvolution.h
    core/YSFFICH.cpp
    core/YSFFICH.h
    core/audioengine.cpp
    core/audioengine.h
    core/cbptc19696.cpp
    core/cbptc19696.h
    core/cgolay2087.cpp
    core/cgolay2087.h
    core/chamming.cpp
    core/chamming.h
    core/crs129.cpp
    core/crs129.h
    core/dcs.cpp
    core/dcs.h
    core/dmr.cpp
    core/dmr.h
    core/droidstar.cpp
    core/droidstar.h
    core/httpmanager.cpp
    core/httpmanager.h
    core/iax.cpp
    core/iax.h
    core/iaxdefines.h
    core/imbe_vocoder/aux_sub.cc
    core/imbe_vocoder/aux_sub.h
    core/imbe_vocoder/basic_op.h
    core/imbe_vocoder/basicop2.cc
    core/imbe_vocoder/ch_decode.cc
    core/imbe_vocoder/ch_decode.h
    core/imbe_vocoder/ch_encode.cc
    core/imbe_vocoder/ch_encode.h
    core/imbe_vocoder/dc_rmv.cc
    core/imbe_vocoder/dc_rmv.h
    core/imbe_vocoder/decode.cc
    core/imbe_vocoder/decode.h
    core/imbe_vocoder/dsp_sub.cc
    core/imbe_vocoder/dsp_sub.h
    core/imbe_vocoder/encode.cc
    core/imbe_vocoder/encode.h
    core/imbe_vocoder/globals.h
    core/imbe_vocoder/imbe.h
    core/imbe_vocoder/imbe_vocoder.cc
    core/imbe_vocoder/imbe_vocoder.h
    core/imbe_vocoder/imbe_vocoder_api.h
    core/imbe_vocoder/imbe_vocoder_impl.cc
    core/imbe_vocoder/imbe_vocoder_impl.h
    core/imbe_vocoder/math_sub.cc
    core/imbe_vocoder/math_sub.h
    core/imbe_vocoder/pe_lpf.cc
    core/imbe_vocoder/pe_lpf.h
    core/imbe_vocoder/pitch_est.cc
    core/imbe_vocoder/pitch_est.h
    core/imbe_vocoder/pitch_ref.cc
    core/imbe_vocoder/pitch_ref.h
    core/imbe_vocoder/qnt_sub.cc
    core/imbe_vocoder/qnt_sub.h
    core/imbe_vocoder/rand_gen.cc
    core/imbe_vocoder/rand_gen.h
    core/imbe_vocoder/sa_decode.cc
    core/imbe_vocoder/sa_decode.h
    core/imbe_vocoder/sa_encode.cc
    core/imbe_vocoder/sa_encode.h
    core/imbe_vocoder/sa_enh.cc
    core/imbe_vocoder/sa_enh.h
    core/imbe_vocoder/tbls.cc
    core/imbe_vocoder/tbls.h
    core/imbe_vocoder/typedef.h
    core/imbe_vocoder/typedefs.h
    core/imbe_vocoder/uv_synt.cc
    core/imbe_vocoder/uv_synt.h
    core/imbe_vocoder/v_synt.cc
    core/imbe_vocoder/v_synt.h
    core/imbe_vocoder/v_uv_det.cc
    core/imbe_vocoder/v_uv_det.h
    core/mbe/ambe3600x2400.c
    core/mbe/ambe3600x2400_const.h
    core/mbe/ambe3600x2450.c
    core/mbe/ambe3600x2450_const.h
    core/mbe/ecc.c
    core/mbe/ecc_const.h
    core/mbe/mbelib.c
    core/mbe/mbelib.h
    core/mbe/mbelib_const.h
    core/mbe/mbelib_parms.h
    core/mbe/mbevocoder.cpp
    core/mbe/mbevocoder.h
    core/mbe/mbevocoder_api.h
    core/mbe/vocoder_tables.h
    core/m17.cpp
    core/m17.h
    main.cpp
    core/mode.cpp
    core/mode.h
    core/nxdn.cpp
    core/nxdn.h
    core/p25.cpp
    core/p25.h
    core/ref.cpp
    core/ref.h
    core/xrf.cpp
    core/xrf.h
    core/ysf.cpp
    core/ysf.h
    ${app_icon_resource_windows}
    ${app_icon_macos}
)

if(ANDROID OR IOS)
    qt_add_qml_module(DroidStar
        URI DroidStarApp
        VERSION 1.0
        QML_FILES ui/mobile/Main.qml
        QML_FILES ui/mobile/MainTab.qml
        QML_FILES ui/mobile/SettingsTab.qml
        QML_FILES ui/mobile/LogTab.qml
        QML_FILES ui/mobile/HostsTab.qml
        QML_FILES ui/mobile/StationLogTab.qml
        QML_FILES ui/mobile/AboutTab.qml
        RESOURCES
            ui/shared/bg_texture.bmp
            ui/shared/fonts/arcade_pizzadude/ARCADE.TTF
    )
else()
    qt_add_qml_module(DroidStar
        URI DroidStarApp
        VERSION 1.0
        QML_FILES ui/desktop/MainDesktop.qml
        RESOURCES
            ui/shared/bg_texture.bmp
            ui/shared/fonts/arcade_pizzadude/ARCADE.TTF
    )
endif()

execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    OUTPUT_VARIABLE VERSION_NUMBER
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

target_compile_definitions(DroidStar PRIVATE
    QT_DEPRECATED_WARNINGS
    VERSION_NUMBER="${VERSION_NUMBER}"
)

target_link_libraries(DroidStar PRIVATE
    Qt::Core
    Qt::Gui
    Qt::Multimedia
    Qt::Network
    Qt::Quick
    Qt::QuickControls2
)

if(UNIX AND NOT IOS)
    target_link_libraries(DroidStar PRIVATE
        Qt::SerialPort
    )
endif()

if(WIN32)
    target_link_libraries(DroidStar PRIVATE
        Qt::SerialPort
        ws2_32
    )
    #add_compile_options(-static --enable-stdcall-fixup)
endif()

if(UNIX)
    target_link_libraries(DroidStar PRIVATE
        dl
    )
endif()

if(APPLE)
    set_target_properties(DroidStar PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist)
    target_link_libraries(DroidStar PRIVATE
        "-framework AVFoundation"
    )
    target_link_options(DroidStar PRIVATE "-F${CMAKE_CURRENT_SOURCE_DIR}/Frameworks" "-F/System/Library/Frameworks")
endif()

if(ANDROID)
    include(~/Android/Sdk/android_openssl/android_openssl.cmake)
    add_android_openssl_libraries(DroidStar)
    target_sources(DroidStar PUBLIC
        androidserialport.cpp androidserialport.h
    )

    set_target_properties(DroidStar PROPERTIES
       QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
       QT_ANDROID_VERSION_CODE 90
       #QT_ANDROID_MIN_SDK_VERSION 31
    )
endif()

if(NOT IOS)
    target_sources(DroidStar PUBLIC
        core/serialambe.cpp core/serialambe.h
        core/serialmodem.cpp core/serialmodem.h
    )
endif()

if(FALSE) #set TRUE to use external codec2
    target_compile_definitions(DroidStar PRIVATE
        USE_EXTERNAL_CODEC2
    )
    target_link_libraries(DroidStar PRIVATE
        codec2
    )
else()
    target_sources(DroidStar PUBLIC
        core/codec2/codebooks.cpp
        core/codec2/codec2.cpp
        core/codec2/codec2_api.h
        core/codec2/codec2_internal.h
        core/codec2/defines.h
        core/codec2/kiss_fft.cpp core/codec2/kiss_fft.h
        core/codec2/lpc.cpp core/codec2/lpc.h
        core/codec2/nlp.cpp core/codec2/nlp.h
        core/codec2/pack.cpp
        core/codec2/qbase.cpp core/codec2/qbase.h
        core/codec2/quantise.cpp core/codec2/quantise.h
    )
endif()

if(FALSE) # set TRUE for flite
    target_compile_definitions(DroidStar PRIVATE
        USE_FLITE
    )
    target_link_libraries(DroidStar PRIVATE
        asound
        flite_cmu_us_awb
        flite_cmu_us_kal16
        flite_cmu_us_rms
        flite_cmu_us_slt
        flite_cmulex
        flite_usenglish
        flite
    )
endif()

if(FALSE) # set TRUE for md380_vocoder
    target_compile_definitions(DroidStar PRIVATE
        USE_MD380_VOCODER
    )
    target_link_libraries(DroidStar PRIVATE
        md380_vocoder
        #/home/nostar/Android/Sdk/local/libmd380_vocoder.a
        # -Xlinker --section-start=.firmware=0x0800C000 -Xlinker --section-start=.sram=0x20000000
    )
endif()

install(TARGETS DroidStar
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_app_script(
    TARGET DroidStar
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)
install(SCRIPT ${deploy_script})
