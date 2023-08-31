start_speculos "$seed"
sleep 0.2
expect_full_text "Tezos Wallet" "ready for" "safe signing"
send_apdu 800f000211048000002c800006c18000000080000000
expect_apdu_return 9000
send_apdu 800f81022305020000001d0100000004434143410100000004504f504f0100000006424f5544494e
expect_section_content nanosp Expression '{"CACA";"POPO";"BOUDIN"}'
press_button right
expect_full_text "Accept?" "Press both buttons to accept."
press_button both
check_tlv_signature 84e475e38707140e725019e91f036e341fa4a2c8752b7828f37bbf91061b0e0a 9000 p2pk67fq5pzuMMABZ9RDrooYbLrgmnQbLt8z7PTGM9mskf7LXS5tdBG 05020000001d0100000004434143410100000004504f504f0100000006424f5544494e
press_button right
press_button right
press_button both
expect_exited
