start_speculos "$seed"
sleep 0.2
expect_full_text "ready for" "safe signing"
# INS_AUTHORIZE_BAKING
send_apdu 8001000000
expect_apdu_return $ERR_INVALID_INS
# INS_SIGN_UNSAFE
send_apdu 8005000000
expect_apdu_return $ERR_INVALID_INS
# INS_RESET
send_apdu 8006000000
expect_apdu_return $ERR_INVALID_INS
# INS_QUERY_AUTH_KEY
send_apdu 8007000000
expect_apdu_return $ERR_INVALID_INS
# INS_QUERY_MAIN_HWM
send_apdu 8008000000
expect_apdu_return $ERR_INVALID_INS
# INS_SETUP
send_apdu 800a000000
expect_apdu_return $ERR_INVALID_INS
# INS_QUERY_ALL_HWM
send_apdu 800b000000
expect_apdu_return $ERR_INVALID_INS
# INS_DEAUTHORIZE
send_apdu 800c000000
expect_apdu_return $ERR_INVALID_INS
# INS_QUERY_AUTH_KEY_WITH_CURVE
send_apdu 800d000000
expect_apdu_return $ERR_INVALID_INS
# INS_HMAC
send_apdu 800e000000
expect_apdu_return $ERR_INVALID_INS
# Unknown instruction
send_apdu 80ff000000
expect_apdu_return $ERR_INVALID_INS
press_button right
press_button right
press_button both
expect_exited
