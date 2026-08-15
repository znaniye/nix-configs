if(CONFIG_ZMK_NIX_SCREEN)
  target_sources(app PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/status_screen.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/art_nix_logo.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/art_lambda.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/art_glyphs.c
  )
endif()
