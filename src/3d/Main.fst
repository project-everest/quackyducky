module Main
open FStar.IO
open FStar.All
open Ast
open ParserDriver
module T = Target
open FStar.ST
#push-options "--z3rlimit_factor 2"

let open_write_file (s:string) : ML FStar.IO.fd_write =
  FStar.IO.print_string (FStar.Printf.sprintf "Writing file %s\n" s);
  FStar.IO.open_write_file s

let process_file (fn: string) : ML unit =
    let modul = Options.get_module_name fn in
    Options.debug_print_string (FStar.Printf.sprintf "Processing file: %s\nModule name: %s\n" fn modul);
    let decls = ParserDriver.parse fn in
    Options.debug_print_string "=============After parsing=============\n";
    Options.debug_print_string (print_decls decls);
    Options.debug_print_string "\n";
    let decls = Desugar.desugar decls in
    Options.debug_print_string "=============After desugaring=============\n";
    Options.debug_print_string (print_decls decls);
    Options.debug_print_string "\n";
    let decls, env = Binding.bind_prog decls in
    Options.debug_print_string "=============After binding=============\n";
    Options.debug_print_string (print_decls decls);
    Options.debug_print_string "\n";
    let decls = BitFields.eliminate env decls in
    Options.debug_print_string "=============After bitflds=============\n";
    Options.debug_print_string (print_decls decls);
    Options.debug_print_string "\n";
    let decls = Simplify.simplify_prog env decls in
    Options.debug_print_string "=============After simplify============\n";
    Options.debug_print_string (print_decls decls);
    Options.debug_print_string "\n";
    let decls = InlineSingletonRecords.simplify_prog decls in
    Options.debug_print_string "=============After inline singletons============\n";
    Options.debug_print_string (print_decls decls);
    Options.debug_print_string "\n";
    let t_decls = Translate.translate_decls env decls in

    let fst_file =
      open_write_file
        (Printf.sprintf "%s/%s.fst"
          (Options.get_output_dir())
          modul) in
    FStar.IO.write_string fst_file (Target.print_decls modul t_decls);
    FStar.IO.close_write_file fst_file;


    let fsti_file =
      open_write_file
        (Printf.sprintf "%s/%s.fsti"
          (Options.get_output_dir())
          modul) in
    FStar.IO.write_string fsti_file (Target.print_decls_signature modul t_decls);
    FStar.IO.close_write_file fsti_file;

    let wrapper_header, wrapper_impl = Target.print_c_entry modul t_decls in

    let c_file =
      open_write_file
        (Printf.sprintf "%s/%sWrapper.c"
          (Options.get_output_dir())
          modul) in
    FStar.IO.write_string c_file wrapper_impl;
    FStar.IO.close_write_file c_file;

    let h_file =
      open_write_file
        (Printf.sprintf "%s/%sWrapper.h"
          (Options.get_output_dir())
          modul) in
    FStar.IO.write_string h_file wrapper_header;
    FStar.IO.close_write_file h_file


let go () : ML unit =
  let files = Options.parse_cmd_line() in
  List.iter process_file files

#push-options "--warn_error -272" //top-level effects are okay
#push-options "--admit_smt_queries true" //explicitly not handling all exceptions, so that we can meaningful backtraces
let _ =
  try go()
  with
    | Error msg ->
      FStar.IO.print_string msg;
      raise (Error msg)
#pop-options