start_speculos "$seed"
sleep 0.2
expect_full_text "ready for" "safe signing"
send_apdu 8003000211048000002c800006c18000000080000000
expect_section_content nanos \
    "Provide Key" \
    'tz3UMNyvQeMj6mQSftW2aV2XaWd3afTAM1d5'
press_button right
expect_full_text "Accept?"
press_button both
expect_apdu_return 410497f4d381101d2908a13669313faec5dbf6693985584f96268ea2c25178199ddd1aad041e7564795eb4b9a4f379e8cdc0c8391f7b2880613771fff76e6a6b05cf9000
press_button right
press_button right
press_button both
expect_exited