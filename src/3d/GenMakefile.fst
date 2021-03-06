module GenMakefile
module OS = OS

type rule_type =
  | EverParse
  | CC
  | Nop (* to simulate multiple-target rules *)

type rule_t = {
  ty: rule_type;
  from: list string;
  to: string;
  args: string;
}

let input_dir = "$(EVERPARSE_INPUT_DIR)"
let output_dir = "$(EVERPARSE_OUTPUT_DIR)"

let print_gnu_make_rule
  (r: rule_t)
: Tot string
= 
  let rule = Printf.sprintf "%s : %s\n" r.to (String.concat " " r.from) in
  match r.ty with
  | Nop -> Printf.sprintf "%s\n" rule
  | _ ->
    let cmd =
      match r.ty with
      | EverParse -> Printf.sprintf "$(EVERPARSE_CMD) --odir %s" output_dir
      | CC -> Printf.sprintf "$(CC) $(CFLAGS) -I %s -c" ("$(EVERPARSE_HOME)" `OS.concat` "src" `OS.concat` "3d")
    in
    let rule = Printf.sprintf "%s\t%s %s\n\n" rule cmd r.args in
    rule

let mk_input_filename
  (file: string)
: Tot string
= input_dir `OS.concat` OS.basename file

let mk_filename
  (modul: string)
  (ext: string)
: Tot string
= output_dir `OS.concat` (Printf.sprintf "%s.%s" modul ext)

let produce_types_checked_rule
  (g: Deps.dep_graph)
  (modul: string)
: Tot rule_t
= let types_fst = mk_filename modul "Types.fst" in 
  {
    ty = EverParse;
    from = types_fst :: List.Tot.map (fun m -> mk_filename m "fsti.checked") (Deps.dependencies g modul);
    to = mk_filename modul "Types.fst.checked";
    args = Printf.sprintf "--__micro_step verify %s" types_fst;
  }

let produce_fsti_checked_rule
  (g: Deps.dep_graph)
  (modul: string)
: Tot rule_t
= let fsti = mk_filename modul "fsti" in
  {
    ty = EverParse;
    from = fsti :: mk_filename modul "Types.fst.checked" :: List.Tot.map (fun m -> mk_filename m "fsti.checked") (Deps.dependencies g modul);
    to = mk_filename modul "fsti.checked";
    args = Printf.sprintf "--__micro_step verify %s" fsti;
  }

let produce_fst_checked_rule
  (g: Deps.dep_graph)
  (modul: string)
: Tot rule_t
= let fst = mk_filename modul "fst" in
  {
    ty = EverParse;
    from = fst :: mk_filename modul "fsti.checked" :: List.Tot.map (fun m -> mk_filename m "fsti.checked") (Deps.dependencies g modul);
    to = mk_filename modul "fst.checked";
    args = Printf.sprintf "--__micro_step verify %s" fst;
  }

let produce_types_krml_rule
  (g: Deps.dep_graph)
  (modul: string)
: Tot rule_t
=
  {
    ty = EverParse;
    from = mk_filename modul "Types.fst.checked" :: List.Tot.map (fun m -> mk_filename m "fst.checked") (Deps.dependencies g modul);
    to = mk_filename (Printf.sprintf "%s_Types" modul) "krml";
    args = Printf.sprintf "--__micro_step extract %s" (mk_filename modul "Types.fst");
  }

let produce_krml_rule
  (g: Deps.dep_graph)
  (modul: string)
: Tot rule_t
=
  {
    ty = EverParse;
    from = mk_filename modul "fst.checked" :: List.Tot.map (fun m -> mk_filename m "fst.checked") (Deps.dependencies g modul);
    to = mk_filename modul "krml";
    args = Printf.sprintf "--__micro_step extract %s" (mk_filename modul "fst");
  }

let produce_nop_rule
  (from: list string)
  (to: string)
: Tot rule_t
=
  {
    ty = Nop;
    from = from;
    to = to;
    args = "";
  }

let produce_fst_rules
  (g: Deps.dep_graph)
  (clang_format: bool)
  (file: string)
: FStar.All.ML (list rule_t)
=
  let modul = Options.get_module_name file in
  let to = mk_filename modul "Types.fst" in
  {
    ty = EverParse;
    from =
      (if clang_format then [mk_filename "" "clang-format"] else []) `List.Tot.append`
      [mk_input_filename file];
    to = to; (* IMPORTANT: relies on the fact that 3d writes the Types.fst first *)
    args = Printf.sprintf "--no_batch %s" (mk_input_filename file);
  } ::
  List.Tot.map (produce_nop_rule [to]) [
    mk_filename modul "fsti";
    mk_filename modul "fst";
  ] `List.Tot.append`
  List.Tot.map
    (produce_nop_rule
      begin
        (if OS.file_exists (Printf.sprintf "%s.copyright.txt" file) then [mk_input_filename (Printf.sprintf "%s.copyright.txt" file)] else []) `List.Tot.append`
        [to]
      end
    )
    begin
      begin if Deps.has_entrypoint g modul
        then [
          mk_filename (Printf.sprintf "%sWrapper" modul) "h";
          mk_filename (Printf.sprintf "%sWrapper" modul) "c";
        ]
        else []
      end `List.Tot.append` begin
        if Deps.has_static_assertions g modul
        then [mk_filename (Printf.sprintf "%sStaticAssertions" modul) "c"]
        else []
      end
    end

let produce_h_rules
  (g: Deps.dep_graph)
  (clang_format: bool)
  (file: string)
: FStar.All.ML (list rule_t)
=
  let all_files = Deps.collect_and_sort_dependencies_from_graph g [file] in
  let to = mk_filename (Options.get_module_name file) "c" in
  let copyright = mk_input_filename (Printf.sprintf "%s.3d.copyright.txt" (Options.get_module_name file)) in
  {
    ty = EverParse;
    from =
      (if clang_format then [mk_filename "" "clang-format"] else []) `List.Tot.append`
      (if OS.file_exists (Printf.sprintf "%s.copyright.txt" file) then [copyright] else []) `List.Tot.append`
      List.map (fun f -> mk_filename (Options.get_module_name f) "krml") all_files `List.Tot.append`
      List.map (fun f -> mk_filename (Printf.sprintf "%s_Types" (Options.get_module_name f)) "krml") all_files
      ;
    to = to; (* IMPORTANT: relies on the fact that kremlin generates .c files BEFORE .h files *)
    args = Printf.sprintf "--__produce_c_from_existing_krml %s" (mk_input_filename file);
  } ::
  [produce_nop_rule [to] (mk_filename (Options.get_module_name file) "h")]

let produce_o_rule
  (modul: string)
: Tot rule_t
=
  let c = mk_filename modul "c" in
  let o = mk_filename modul "o" in
  {
    ty = CC;
    from = [c; mk_filename modul "h"];
    to = o;
    args = Printf.sprintf "-o %s %s" o c;
  }

let produce_wrapper_o_rule
  (g: Deps.dep_graph)
  (modul: string)
: Tot (list rule_t)
=
  let wc = mk_filename (Printf.sprintf "%sWrapper" modul) "c" in
  let wh = mk_filename (Printf.sprintf "%sWrapper" modul) "h" in
  let wo = mk_filename (Printf.sprintf "%sWrapper" modul) "o" in
  let h = mk_filename modul "h" in
  if Deps.has_entrypoint g modul
  then [{
    ty = CC;
    from = [wc; wh; h];
    to = wo;
    args = Printf.sprintf "-o %s %s" wo wc;
  }]
  else []

let produce_static_assertions_o_rule
  (g: Deps.dep_graph)
  (modul: string)
: Tot (list rule_t)
=
  let wc = mk_filename (Printf.sprintf "%sStaticAssertions" modul) "c" in
  let wo = mk_filename (Printf.sprintf "%sStaticAssertions" modul) "o" in
  let h = mk_filename modul "h" in
  if Deps.has_static_assertions g modul
  then [{
    ty = CC;
    from = [wc; h];
    to = wo;
    args = Printf.sprintf "-o %s %s" wo wc;
  }]
  else []

let produce_clang_format_rule
  (clang_format: bool)
: Tot (list rule_t)
=
  if clang_format
  then [{
   ty = EverParse;
   from = [];
   to = mk_filename "" "clang-format";
   args = "--__micro_step copy_clang_format";
  }] else []

noeq
type produce_makefile_res = {
  rules: list rule_t;
  graph: Deps.dep_graph;
  all_files: list string;
}

let produce_makefile
  (skip_o_rules: bool)
  (clang_format: bool)
  (files: list string)
: FStar.All.ML produce_makefile_res
=
  let g = Deps.build_dep_graph_from_list files in
  let all_files = Deps.collect_and_sort_dependencies_from_graph g files in
  let all_modules = List.map Options.get_module_name all_files in
  let rules =
    produce_clang_format_rule clang_format `List.Tot.append`
    (if skip_o_rules then [] else
      List.Tot.concatMap (produce_wrapper_o_rule g) all_modules `List.Tot.append`
      List.Tot.concatMap (produce_static_assertions_o_rule g) all_modules `List.Tot.append`
      List.Tot.map produce_o_rule all_modules
    ) `List.Tot.append`
    List.concatMap (produce_fst_rules g clang_format) all_files `List.Tot.append`
    List.Tot.map (produce_types_checked_rule g) all_modules `List.Tot.append`
    List.Tot.map (produce_fsti_checked_rule g) all_modules `List.Tot.append`
    List.Tot.map (produce_fst_checked_rule g) all_modules `List.Tot.append`
    List.Tot.map (produce_types_krml_rule g) all_modules `List.Tot.append`
    List.Tot.map (produce_krml_rule g) all_modules `List.Tot.append`
    List.concatMap (produce_h_rules g clang_format) all_files
  in {
    graph = g;
    rules = rules;
    all_files = all_files;
  }

let write_gnu_makefile
  (skip_o_rules: bool)
  (clang_format: bool)
  (files: list string)
: FStar.All.ML unit
=
  let makefile = Options.get_makefile_name () in
  let file = FStar.IO.open_write_file makefile in
  let {graph = g; rules; all_files} = produce_makefile skip_o_rules clang_format files in
  FStar.IO.write_string file (String.concat "" (List.Tot.map print_gnu_make_rule rules));
  let write_all_ext_files (ext_cap: string) (ext: string) : FStar.All.ML unit =
    let ln =
      begin if ext <> "h"
      then
        List.concatMap (fun f -> let m = Options.get_module_name f in if Deps.has_static_assertions g m then [mk_filename (Printf.sprintf "%sStaticAssertions" m) ext] else []) all_files
      else []
      end `List.Tot.append`
      List.concatMap (fun f -> let m = Options.get_module_name f in if Deps.has_entrypoint g m then [mk_filename (Printf.sprintf "%sWrapper" m) ext] else []) all_files `List.Tot.append`
      List.map (fun f -> mk_filename (Options.get_module_name f) ext) all_files
    in
    FStar.IO.write_string file (Printf.sprintf "EVERPARSE_ALL_%s_FILES=%s\n" ext_cap (String.concat " " ln))
  in
  write_all_ext_files "H" "h";
  write_all_ext_files "C" "c";
  write_all_ext_files "O" "o";
  FStar.IO.close_write_file file

let write_nmakefile = write_gnu_makefile

let write_makefile
  (mtype: HashingOptions.makefile_type)
: Tot (
    (skip_o_rules: bool) ->
    (clang_format: bool) ->
    (files: list string) ->
    FStar.All.ML unit
  )
= match mtype with
  | HashingOptions.MakefileGMake -> write_gnu_makefile
  | HashingOptions.MakefileNMake -> write_nmakefile
