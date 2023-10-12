start_speculos "$seed"
expect_full_text 'ready for' 'safe signing'
# INS_GET_PUBLIC_KEY
send_apdu 8002000411048000002c800006c18000000080000000
expect_apdu_return 6b00
# INS_PROMPT_PUBLIC_KEY
send_apdu 8003000411048000002c800006c18000000080000000
expect_apdu_return 6b00
# INS_SIGN
send_apdu 8004000411048000002c800006c18000000080000000
expect_apdu_return 6b00
# INS_SIGN_WITH_HASH
send_apdu 800f000411048000002c800006c18000000080000000
expect_apdu_return 6b00
press_button right
press_button right
press_button both
expect_exited
