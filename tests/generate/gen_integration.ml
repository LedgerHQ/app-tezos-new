(* Copyright 2023 Nomadic Labs <contact@nomadic-labs.com>
   Copyright 2023 Functori <contact@functori.com>
   Copyright 2023 TriliTech <contact@trili.tech>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License. *)

let shell_escape ppf s =
  Format.fprintf ppf "'";
  String.iter
    (function
      | '\'' -> Format.fprintf ppf "'\\''" | c -> Format.fprintf ppf "%c" c)
    s;
  Format.fprintf ppf "'"

let pp_hex_bytes ppf bytes = Format.fprintf ppf "%a" Hex.pp (Hex.of_bytes bytes)

(** General *)

let start_speculos ppf mnemonic =
  Format.fprintf ppf "start_speculos \"%a\"@." Tezos_client_base.Bip39.pp
    mnemonic

module Device = struct
  type t = Nanos | Nanosp | Nanox

  let of_string_exn = function
    | "nanos" -> Nanos
    | "nanosp" -> Nanosp
    | "nanox" -> Nanox
    | d -> failwith @@ Format.sprintf "invalid device %s" d

  let to_string = function
    | Nanos -> "nanos"
    | Nanosp -> "nanosp"
    | Nanox -> "nanox"
end

let expect_full_text ppf l =
  let pp_space ppf () = Format.fprintf ppf " " in
  let pp_args = Format.pp_print_list ~pp_sep:pp_space shell_escape in
  Format.fprintf ppf "expect_full_text %a@." pp_args l

let expect_section_content ppf ~device ~title content =
  Format.fprintf ppf "expect_section_content %s %a %a@."
    (Device.to_string device) shell_escape title shell_escape content

module Button = struct
  type t = Both | Right | Left

  let press ppf button =
    let button =
      match button with Both -> "both" | Right -> "right" | Left -> "left"
    in
    Format.fprintf ppf "press_button %s@." button
end

let send_apdu ppf packet =
  Format.fprintf ppf "send_apdu %a@." pp_hex_bytes packet

let expect_apdu_return ppf ans =
  Format.fprintf ppf "expect_apdu_return %a@." pp_hex_bytes ans

type async_apdu = { packet : bytes; check : Format.formatter -> unit -> unit }

let send_async_apdus ppf async_apdus =
  let pp_dash_break_line ppf () = Format.fprintf ppf "\\@\n\t" in
  let pp_async_apdu ppf { packet; check } =
    Format.fprintf ppf "%a \"%a\"" pp_hex_bytes packet check ()
  in
  let pp_async_apdus =
    Format.pp_print_list ~pp_sep:pp_dash_break_line pp_async_apdu
  in
  Format.fprintf ppf "send_async_apdus %a%a@." pp_dash_break_line ()
    pp_async_apdus async_apdus

let expect_async_apdus_sent ppf () =
  Format.fprintf ppf "expect_async_apdus_sent@."

let expect_exited ppf () = Format.fprintf ppf "expect_exited@."

let check_tlv_signature_from_sent_apdu ppf ~prefix ~suffix pk message =
  Format.fprintf ppf "check_tlv_signature_from_sent_apdu %a %a %a %a@."
    pp_hex_bytes prefix pp_hex_bytes suffix Tezos_crypto.Signature.Public_key.pp
    pk pp_hex_bytes message

(** Specific *)

let home ppf () =
  expect_full_text ppf [ "Tezos Wallet"; "ready for"; "safe signing" ]

let expect_accept ppf = function
  | Device.Nanos -> expect_full_text ppf [ "Accept?" ]
  | Device.Nanosp | Device.Nanox ->
      expect_full_text ppf [ "Accept?"; "Press both buttons to accept." ]

let expect_reject ppf = function
  | Device.Nanos -> expect_full_text ppf [ "Reject?" ]
  | Device.Nanosp | Device.Nanox ->
      expect_full_text ppf [ "Accept?"; "Press both buttons to reject." ]

let expect_quit ppf () = expect_full_text ppf [ "Quit?" ]

let accept ppf device =
  expect_accept ppf device;
  Button.(press ppf Both)

let reject ppf device =
  expect_reject ppf device;
  Button.(press ppf Both)

let quit ppf () =
  expect_quit ppf ();
  Button.(press ppf Both)

type screen = { title : string; contents : string }

let make_screen ~title contents = { title; contents }

let expected_screen ppf ~device { title; contents } =
  expect_section_content ppf ~device ~title contents

let go_through_screens ppf ~device screens =
  List.iter
    (fun screen ->
      expected_screen ppf ~device screen;
      Button.(press ppf Right))
    screens

let sign ppf ~signer:Apdu.Signer.({ sk; pk; _ } as signer) ~watermark bin =
  let watermark = Tezos_crypto.Signature.bytes_of_watermark watermark in
  let bin = Bytes.cat watermark bin in
  let packets = Apdu.sign ~signer bin in
  let bin_accept_check ppf () =
    let bin_hash = Tezos_crypto.Blake2B.(to_bytes (hash_bytes [ bin ])) in
    if Apdu.Curve.(deterministic_sig (of_sk sk)) then
      let sign =
        Tezos_crypto.Signature.to_bytes (Tezos_crypto.Signature.sign sk bin)
      in
      expect_apdu_return ppf
        (Bytes.concat Bytes.empty [ bin_hash; sign; Apdu.success ])
    else
      check_tlv_signature_from_sent_apdu ppf ~prefix:bin_hash
        ~suffix:Apdu.success pk bin
  in
  let last_index = List.length packets - 1 in
  let async_apdus =
    List.mapi
      (fun index packet ->
        let check ppf () =
          if index = last_index then bin_accept_check ppf ()
          else expect_apdu_return ppf Apdu.success
        in
        { packet; check })
      packets
  in
  send_async_apdus ppf async_apdus

open Tezos_protocol_017_PtNairob
open Tezos_micheline

let rec pp_node ~wrap ppf (node : Protocol.Script_repr.node) =
  match node with
  | String (_, s) -> Format.fprintf ppf "%S" s
  | Bytes (_, bs) ->
      Format.fprintf ppf "0x%s"
        (String.uppercase_ascii (Hex.show (Hex.of_bytes bs)))
  | Int (_, n) -> Format.fprintf ppf "%s" (Z.to_string n)
  | Seq (_, l) ->
      Format.fprintf ppf "{%a}"
        (Format.pp_print_list
           ~pp_sep:(fun ppf () -> Format.fprintf ppf ";")
           (pp_node ~wrap:false))
        l
  | Prim (_, p, l, a) ->
      let lwrap, rwrap =
        if wrap && (l <> [] || a <> []) then ("(", ")") else ("", "")
      in
      Format.fprintf ppf "%s%s%a%s%s" lwrap
        (Protocol.Michelson_v1_primitives.string_of_prim p)
        (fun ppf l ->
          List.iter (fun e -> Format.fprintf ppf " %a" (pp_node ~wrap:true) e) l)
        l
        (if a = [] then "" else " " ^ String.concat " " a)
        rwrap

let node_to_screens ~title ppf node =
  let whole = Format.asprintf "%a" (pp_node ~wrap:false) node in
  Format.fprintf ppf "# full output: %s@\n" whole;
  [ make_screen ~title whole ]

let pp_opt_field pp ppf = function
  | None -> Format.fprintf ppf "Field unset"
  | Some v -> Format.fprintf ppf "%a" pp v

let pp_tz ppf tz = Format.fprintf ppf "%a tz" Protocol.Alpha_context.Tez.pp tz

let pp_lazy_expr ppf lazy_expr =
  let expr = Result.get_ok @@ Protocol.Script_repr.force_decode lazy_expr in
  Format.fprintf ppf "%a" (pp_node ~wrap:false) (Micheline.root expr)

let pp_string_binary ppf s = Format.fprintf ppf "%a" Hex.pp (Hex.of_string s)

let operation_to_screens
    ( (_shell : Tezos_base.Operation.shell_header),
      (Contents_list contents : Protocol.Alpha_context.packed_contents_list) ) =
  let open Protocol.Alpha_context in
  let make_screen ~title fmt = Format.kasprintf (make_screen ~title) fmt in
  let screen_of_manager n (type t)
      (Manager_operation { fee; operation; storage_limit; _ } :
        t Kind.manager contents) =
    let aux ~kind operation_screens =
      let operation_index = Format.asprintf "Operation (%d)" n in
      let manager_screens =
        [
          make_screen ~title:operation_index "%s" kind;
          make_screen ~title:"Fee" "%a" pp_tz fee;
          make_screen ~title:"Storage limit" "%s" (Z.to_string storage_limit);
        ]
      in
      manager_screens @ operation_screens
    in
    match operation with
    | Delegation public_key_hash_opt ->
        aux ~kind:"Delegation"
          [
            make_screen ~title:"Delegate" "%a"
              (pp_opt_field Tezos_crypto.Signature.Public_key_hash.pp)
              public_key_hash_opt;
          ]
    | Increase_paid_storage { amount_in_bytes; destination } ->
        aux ~kind:"Increase paid storage"
          [
            make_screen ~title:"Amount" "%s" (Z.to_string amount_in_bytes);
            make_screen ~title:"Destination" "%a" Protocol.Contract_hash.pp
              destination;
          ]
    | Origination { delegate; script = { code; storage }; credit } ->
        aux ~kind:"Origination"
          [
            make_screen ~title:"Balance" "%a" pp_tz credit;
            make_screen ~title:"Delegate" "%a"
              (pp_opt_field Tezos_crypto.Signature.Public_key_hash.pp)
              delegate;
            make_screen ~title:"Code" "%a" pp_lazy_expr code;
            make_screen ~title:"Storage" "%a" pp_lazy_expr storage;
          ]
    | Register_global_constant { value } ->
        aux ~kind:"Register global constant"
          [ make_screen ~title:"Value" "%a" pp_lazy_expr value ]
    | Reveal public_key ->
        aux ~kind:"Reveal"
          [
            make_screen ~title:"Public key" "%a"
              Tezos_crypto.Signature.Public_key.pp public_key;
          ]
    | Set_deposits_limit tez_opt ->
        aux ~kind:"Set deposit limit"
          [
            make_screen ~title:"Staking limit" "%a" (pp_opt_field pp_tz) tez_opt;
          ]
    | Transaction { amount; entrypoint; destination; parameters } ->
        let parameter =
          if
            Protocol.Script_repr.is_unit_parameter parameters
            && Protocol.Entrypoint_repr.is_default entrypoint
          then []
          else
            [
              make_screen ~title:"Entrypoint" "%a" Entrypoint.pp entrypoint;
              make_screen ~title:"Parameter" "%a" pp_lazy_expr parameters;
            ]
        in
        aux ~kind:"Transaction"
          ([
             make_screen ~title:"Amount" "%a" pp_tz amount;
             make_screen ~title:"Destination" "%a" Contract.pp destination;
           ]
          @ parameter)
    | Transfer_ticket
        { contents; ty; ticketer; amount; destination; entrypoint } ->
        aux ~kind:"Transfer ticket"
          [
            make_screen ~title:"Contents" "%a" pp_lazy_expr contents;
            make_screen ~title:"Type" "%a" pp_lazy_expr ty;
            make_screen ~title:"Ticketer" "%a" Contract.pp ticketer;
            make_screen ~title:"Amount" "%s"
              Protocol.Script_int.(to_string (amount :> n num));
            make_screen ~title:"Destination" "%a" Contract.pp destination;
            make_screen ~title:"Entrypoint" "%a" Entrypoint.pp entrypoint;
          ]
    | Update_consensus_key public_key ->
        aux ~kind:"Set consensus key"
          [
            make_screen ~title:"Public key" "%a"
              Tezos_crypto.Signature.Public_key.pp public_key;
          ]
    | Sc_rollup_add_messages { messages } ->
        let make_screen_message i message =
          let title = Format.sprintf "Message (%d)" i in
          make_screen ~title "%a" pp_string_binary message
        in
        aux ~kind:"SR: send messages" @@ List.mapi make_screen_message messages
    | Sc_rollup_execute_outbox_message
        { rollup; cemented_commitment; output_proof } ->
        aux ~kind:"SR: execute outbox message"
          [
            make_screen ~title:"Rollup" "%a" Sc_rollup_repr.Address.pp rollup;
            make_screen ~title:"Commitment" "%a" Sc_rollup.Commitment.Hash.pp
              cemented_commitment;
            make_screen ~title:"Output proof" "%a" pp_string_binary output_proof;
          ]
    | _ -> assert false
  in
  let rec screen_of_operations : type t. int -> t contents_list -> screen list =
   fun n -> function
    | Single (Manager_operation _ as m) -> screen_of_manager n m
    | Cons ((Manager_operation _ as m), rest) ->
        screen_of_manager n m @ screen_of_operations (succ n) rest
    | _ -> assert false
  in
  screen_of_operations 0 contents

let mnemonic_of_string s =
  Option.get @@ Tezos_client_base.Bip39.of_words @@ String.split_on_char ' ' s

let zebra =
  mnemonic_of_string
    "zebra zebra zebra zebra zebra zebra zebra zebra zebra zebra zebra zebra \
     zebra zebra zebra zebra zebra zebra zebra zebra zebra zebra zebra zebra"

let seed12 =
  mnemonic_of_string
    "spread husband dish drop file swap dog foil verb nut orient chicken"

let seed15 =
  mnemonic_of_string
    "tonight jump steak foil time sudden detect text rifle liberty volcano \
     riot person guess unaware"

let seed21 =
  mnemonic_of_string
    "around dignity equal spread between young lawsuit interest climb wide \
     that panther rather mom snake scene ecology reunion ice illegal brush"

let seed24 =
  mnemonic_of_string
    "small cool word clock copy badge jungle pole cool horror woman miracle \
     silver library foster cinnamon spring discover gauge faint hammer test \
     air cream"

let default_path = [ 44; 1729; 0; 0 ]
let path_0 = [ 0 ]
let path_2_11_5 = [ 2; 11; 5 ]
let path_17_8_6_9 = [ 17; 8; 6; 9 ]
let path_9_12_13_8_78 = [ 9; 12; 13; 8; 78 ]

let tz1_signers =
  [
    (* tz1dyX3B1CFYa2DfdFLyPtiJCfQRUgPVME6E *)
    Apdu.Signer.make ~mnemonic:zebra ~path:default_path
      ~sk:"edsk2tUyhVvGj9B1S956ZzmaU4bC9J7t8xVBH52fkAoZL25MHEwacd";
    (* tz1NxVR43U25oudr9QPCjXycDNaH1arZZ5fL *)
    Apdu.Signer.make ~mnemonic:seed12 ~path:path_0
      ~sk:"edsk3xdyqj4YH64DKQ3ihVktjs2x5DagcoP3yNbdqPg3FAibHM1EU2";
    (* tz1PVqTSCw2JKxXcwSLgd5Zad18djpvcvPMF *)
    Apdu.Signer.make ~mnemonic:seed15 ~path:path_2_11_5
      ~sk:"edsk3qtimAD78T5PBdkAXwjPHYa1tEXJ3jmMcVgNSXuXs9wjsnWnrX";
    (* tz1aex9GimxigprKi8MQK3j6sSisDpbtRBXw *)
    Apdu.Signer.make ~mnemonic:seed21 ~path:path_17_8_6_9
      ~sk:"edsk3xW7FFGdpFTUzqd2dbRVDGt6vK2XrRfQU5VjXKFABdN3mbmRkH";
    (* tz1ZAxU3Q39BSJWoHzEcPmt8U36iHmdCcZ2K *)
    Apdu.Signer.make ~mnemonic:seed24 ~path:path_9_12_13_8_78
      ~sk:"edsk2vPx2hnTsef6EeuD846PoHTja7dM96YtZ26S3Xz4KP36a2m6k1";
    (* tz1NKmt8bGYc5guuJyXPTkEbvBHXHBHVALhc *)
    Apdu.Signer.make ~mnemonic:seed12 ~path:default_path
      ~sk:"edsk3q2GyniEU2jGxw7uLFPys4AfALs96VE64d7kr7NXhtN4w8RUue";
    (* tz1aKnxJdtJQ89Hp5HeXMxgJnnyNHjyAUmSb *)
    Apdu.Signer.make ~mnemonic:seed15 ~path:path_0
      ~sk:"edsk35nft3nYCBpzdXqKCL1VPpVTa3NFTDGj7QqSxc1auzkjz2znTW";
    (* tz1VeeXEdqU9TjfAvPNKpUopB1jXJAZh9egp *)
    Apdu.Signer.make ~mnemonic:seed21 ~path:path_2_11_5
      ~sk:"edsk3VTt2ikBiYrt1LKM9juE71Tfg6YmjdUGR4PzT2wuV5uEJ9vTDM";
    (* tz1dHwBzesqaqdNdsMGDu2xjAPvirzmx4BTL *)
    Apdu.Signer.make ~mnemonic:seed24 ~path:path_17_8_6_9
      ~sk:"edsk3mfq95CqPnQgcj38KpAz8taNjQY5tQYvNRKojXLKKjhZC72z2H";
    (* tz1ez9eEyAxuDZACjHdCXym43UQDdMNa3LEL *)
    Apdu.Signer.make ~mnemonic:zebra ~path:path_9_12_13_8_78
      ~sk:"edsk3eZBgFAf1VtdibfxoCcihxXje9S3th7jdEgVA2kHG82EKYNKNm";
  ]

let tz2_signer =
  (* tz2GB5YHqF4UzQ8GP5yUqdhY9oVWRXCY2hPU *)
  Apdu.Signer.make ~mnemonic:zebra ~path:default_path
    ~sk:"spsk2Pfx9chqXVbz2tW7ze4gGU4RfaiK3nSva77bp69zHhFho2zTze"

let gen_signer = QCheck2.Gen.oneofl tz1_signers

let gen_expect_test_sign ppf ~device ~watermark bin screens =
  Format.fprintf ppf "# full input: %a@." pp_hex_bytes bin;
  let signer = QCheck2.Gen.generate1 ~rand:Gen_utils.random_state gen_signer in
  Format.fprintf ppf "# signer: %a@." Tezos_crypto.Signature.Public_key_hash.pp
    signer.pkh;
  Format.fprintf ppf "# path: %a@." Apdu.Path.pp signer.path;
  start_speculos ppf signer.mnemonic;
  home ppf ();
  sign ppf ~signer ~watermark bin;
  go_through_screens ppf ~device screens;
  accept ppf device;
  expect_async_apdus_sent ppf ()

let gen_expect_test_sign_micheline_data ~device ppf bin =
  let screens =
    let node = Gen_micheline.decode bin in
    node_to_screens ~title:"Expression" ppf (Micheline.root node)
  in
  gen_expect_test_sign ppf ~device ~watermark:Gen_micheline.watermark bin
    screens

let gen_expect_test_sign_operation ~device ppf bin =
  let screens =
    let op = Gen_operations.decode bin in
    operation_to_screens op
  in
  gen_expect_test_sign ppf ~device ~watermark:Gen_operations.watermark bin
    screens
