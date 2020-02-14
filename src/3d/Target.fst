(*
   Copyright 2019 Microsoft Research

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)
module Target
(* The abstract syntax for the code produced by 3d *)
open FStar.All
module A = Ast
open Binding

let rec expr_eq e1 e2 =
  match e1, e2 with
  | Constant c1, Constant c2 -> c1=c2
  | Identifier i1, Identifier i2 -> A.(i1.v = i2.v)
  | App hd1 args1, App hd2 args2 -> hd1 = hd2 && exprs_eq args1 args2
  | Record t1 fields1, Record t2 fields2 -> A.(t1.v = t2.v) && fields_eq fields1 fields2
  | _ -> false
and exprs_eq es1 es2 =
  match es1, es2 with
  | [], [] -> true
  | e1::es1, e2::es2 -> expr_eq e1 e2 && exprs_eq es1 es2
  | _ -> false
and fields_eq fs1 fs2 =
  match fs1, fs2 with
  | [], [] -> true
  | (i1, e1)::fs1, (i2, e2)::fs2 ->
    A.(i1.v = i2.v)
    && fields_eq fs1 fs2
  | _ -> false
let rec parser_kind_eq k k' =
  match k.pk_kind, k'.pk_kind with
  | PK_return, PK_return -> true
  | PK_impos, PK_impos -> true
  | PK_list,  PK_list -> true
  | PK_base hd1, PK_base hd2 -> A.(hd1.v = hd2.v)
  | PK_filter k, PK_filter k' -> parser_kind_eq k k'
  | PK_and_then k1 k2, PK_and_then k1' k2'
  | PK_glb k1 k2, PK_glb k1' k2' ->
    parser_kind_eq k1 k1'
    && parser_kind_eq k2 k2'
  | _ -> false

////////////////////////////////////////////////////////////////////////////////
// Printing the target AST in F* concrete syntax
////////////////////////////////////////////////////////////////////////////////

let print_ident (i:A.ident) =
  let open A in
  match String.list_of_string i.v with
  | [] -> i.v
  | c0::_ ->
    if FStar.Char.lowercase c0 = c0
    then i.v
    else Ast.reserved_prefix^i.v

let print_integer_type =
  let open A in
  function
   | UInt8 -> "uint8"
   | UInt16 -> "uint16"
   | UInt32 -> "uint32"
   | UInt64 -> "uint64"

let print_op = function
  | Eq -> "="
  | Neq -> "<>"
  | And -> "&&"
  | Or -> "||"
  | Not -> "not"
  | Plus -> "`FStar.UInt32.add`"
  | Minus -> "`FStar.UInt32.sub`"
  | Mul -> "`FStar.UInt32.mul`"
  | Division -> "`FStar.UInt32.div`"
  | LT -> "`FStar.UInt32.lt`"
  | GT -> "`FStar.UInt32.gt`"
  | LE -> "`FStar.UInt32.lte`"
  | GE -> "`FStar.UInt32.gte`"
  | IfThenElse -> "ite"
  | BitFieldOf i -> Printf.sprintf "get_bitfield%d" i
  | Cast from to ->
    Printf.sprintf "FStar.Int.Cast.%s_to_%s" (print_integer_type from) (print_integer_type to)
  | Ext s -> s

let rec print_expr (e:expr) : Tot string =
  match e with
  | Constant c ->
    A.print_constant c
  | Identifier i ->
    print_ident i
  | Record nm fields ->
    Printf.sprintf "{ %s }" (String.concat "; " (print_fields fields))
  | App Eq [e1; e2]
  | App Neq [e1; e2]
  | App And [e1; e2]
  | App Or [e1; e2]
  | App Plus [e1; e2]
  | App Minus [e1; e2]
  | App Mul [e1; e2]
  | App Division [e1; e2]
  | App LT [e1; e2]
  | App GT [e1; e2]
  | App LE [e1; e2]
  | App GE [e1; e2] ->
    Printf.sprintf "(%s %s %s)" (print_expr e1) (print_op (App?.hd e)) (print_expr e2)
  | App Not [e1] ->
    Printf.sprintf "(%s %s)" (print_op (App?.hd e)) (print_expr e1)
  | App IfThenElse [e1;e2;e3] ->
    Printf.sprintf
      "(if %s then %s else %s)"
      (print_expr e1) (print_expr e2) (print_expr e3)
  | App (BitFieldOf i) [e1;e2;e3] ->
    Printf.sprintf
      "(%s %s %s %s)"
      (print_op (BitFieldOf i))
      (print_expr e1) (print_expr e2) (print_expr e3)
  | App op [] ->
    print_op op
  | App op es ->
    Printf.sprintf "(%s %s)" (print_op op) (String.concat " " (print_exprs es))

and print_exprs (es:list expr) : Tot (list string) =
  match es with
  | [] -> []
  | hd::tl -> print_expr hd :: print_exprs tl

and print_fields (fs:_) : Tot (list string) =
  match fs with
  | [] -> []
  | (x, e)::tl ->
    Printf.sprintf "%s = %s" (print_ident x) (print_expr e)
    :: print_fields tl

let rec print_typ (t:typ) : Tot string (decreases t) =
  match t with
  | T_false -> "False"
  | T_app hd args ->
    Printf.sprintf "(%s %s)"
      (print_ident hd)
      (String.concat " " (print_indexes args))
  | T_dep_pair t1 (x, t2) ->
    Printf.sprintf "(%s:%s & %s)"
      (print_ident x)
      (print_typ t1)
      (print_typ t2)
  | T_refine t1 (x, e2) ->
    Printf.sprintf "(%s:%s{%s})"
      (print_ident x)
      (print_typ t1)
      (print_expr e2)
  | T_if_else e t1 t2 ->
    Printf.sprintf "(t_ite %s %s %s)"
      (print_expr e)
      (print_typ t1)
      (print_typ t2)
  | T_pointer t -> Printf.sprintf "B.pointer %s" (print_typ t)
  | T_with_action t _
  | T_with_dep_action t _
  | T_with_comment t _ -> print_typ t

and print_indexes (is:list index) : Tot (list string) (decreases is) =
  match is with
  | [] -> []
  | Inl t::is -> print_typ t::print_indexes is
  | Inr e::is -> print_expr e::print_indexes is

let rec print_kind (k:parser_kind) : Tot string =
  match k.pk_kind with
  | PK_base hd ->
    Printf.sprintf "kind_%s"
      (print_ident hd)
  | PK_list ->
      "kind_nlist"
  | PK_return ->
    "ret_kind"
  | PK_impos ->
    "impos_kind"
  | PK_and_then k1 k2 ->
    Printf.sprintf "(and_then_kind %s %s)"
      (print_kind k1)
      (print_kind k2)
  | PK_glb k1 k2 ->
    Printf.sprintf "(glb %s %s)"
      (print_kind k1)
      (print_kind k2)
  | PK_filter k ->
    Printf.sprintf "(filter_kind %s)"
      (print_kind k)

let rec print_parser (p:parser) : Tot string (decreases p) =
  match p.p_parser with
  | Parse_return v ->
    Printf.sprintf "(parse_ret %s)" (print_expr v)
  | Parse_app hd args ->
    Printf.sprintf "(parse_%s %s)" (print_ident hd) (String.concat " " (print_indexes args))
  | Parse_nlist e p ->
    Printf.sprintf "(parse_nlist %s %s)" (print_expr e) (print_parser p)
  | Parse_pair _ p1 p2 ->
    Printf.sprintf "(%s `parse_pair` %s)" (print_parser p1) (print_parser p2)
  | Parse_dep_pair _ p1 (x, p2)
  | Parse_dep_pair_with_action p1 _ (x, p2) ->
    Printf.sprintf "(%s `parse_dep_pair` (fun %s -> %s))" (print_parser p1) (print_ident x) (print_parser p2)
  | Parse_dep_pair_with_refinement _ _ p1 (x, e) (y, p2)
  | Parse_dep_pair_with_refinement_and_action _ _ p1 (x, e) _ (y, p2) ->
    Printf.sprintf "((%s `parse_filter` (fun %s -> %s)) `parse_dep_pair` (fun %s -> %s))"
                   (print_parser p1)
                   (print_ident x)
                   (print_expr e)
                   (print_ident y)
                   (print_parser p2)
  | Parse_map p1 (x, e) ->
    Printf.sprintf "(%s `parse_map` (fun %s -> %s))" (print_parser p1) (print_ident x) (print_expr e)
  | Parse_refinement _ p1 (x, e)
  | Parse_refinement_with_action _ p1 (x, e) _ ->
    Printf.sprintf "(%s `parse_filter` (fun %s -> %s))" (print_parser p1) (print_ident x) (print_expr e)
  | Parse_weaken_left p1 k ->
    Printf.sprintf "(parse_weaken_left %s %s)" (print_parser p1) (print_kind k)
  | Parse_weaken_right p1 k ->
    Printf.sprintf "(parse_weaken_right %s %s)" (print_parser p1) (print_kind k)
  | Parse_if_else e p1 p2 ->
    Printf.sprintf "(parse_ite %s (fun _ -> %s) (fun _ -> %s))"
      (print_expr e)
      (print_parser p1)
      (print_parser p2)
  | Parse_impos -> "(parse_impos())"
  | Parse_with_error _ p
  | Parse_with_dep_action _ p _
  | Parse_with_action _ p _
  | Parse_with_comment p _ -> print_parser p

let rec print_reader (r:reader) : Tot string =
  match r with
  | Read_u8 -> "read____UINT8"
  | Read_u16 -> "read____UINT16"
  | Read_u32 -> "read____UINT32"
  | Read_app hd args ->
    Printf.sprintf "(read_%s %s)" (print_ident hd) (String.concat " " (print_indexes args))
  | Read_filter r (x, f) ->
    Printf.sprintf "(read_filter %s (fun %s -> %s))"
      (print_reader r)
      (print_ident x)
      (print_expr f)

let rec print_action (a:action) : Tot string =
  let print_atomic_action (a:atomic_action)
    : Tot string
    = match a with
      | Action_return e ->
        Printf.sprintf "(action_return %s)" (print_expr e)
      | Action_abort -> "(action_abort())"
      | Action_field_pos -> "(action_field_pos())"
      | Action_field_ptr -> "(action_field_ptr())"
      | Action_deref i ->
        Printf.sprintf "(action_deref %s)" (print_ident i)
      | Action_assignment lhs rhs ->
        Printf.sprintf "(action_assignment %s %s)" (print_ident lhs) (print_expr rhs)
      | Action_call f args ->
        Printf.sprintf "(%s %s)" (print_ident f) (String.concat " " (List.Tot.map print_expr args))
  in
  match a with
  | Atomic_action a ->
    print_atomic_action a
  | Action_seq hd tl ->
    Printf.sprintf "(action_seq %s %s)"
                    (print_atomic_action hd)
                    (print_action tl)
  | Action_ite hd then_ else_ ->
    Printf.sprintf "(action_ite %s %s %s)"
      (print_expr hd)
      (print_action then_)
      (print_action else_)
  | Action_let i a k ->
    Printf.sprintf "(action_bind \"%s\" %s (fun %s -> %s))"
                   (print_ident i)
                   (print_atomic_action a)
                   (print_ident i)
                   (print_action k)

let rec print_validator (v:validator) : Tot string (decreases v) =
  let is_unit_validator v =
    let open A in
    match v.v_validator with
    | Validate_app ({v="unit"}) [] -> true
    | _ -> false
  in
  match v.v_validator with
  | Validate_return ->
    Printf.sprintf "validate_ret"
  | Validate_app hd args ->
    Printf.sprintf "(validate_%s %s)" (print_ident hd) (String.concat " " (print_indexes args))
  | Validate_nlist e p ->
    Printf.sprintf "(validate_nlist %s %s)" (print_expr e) (print_validator p)
  | Validate_nlist_constant_size_without_actions e p ->
    let n_is_const = match e with
    | Constant (A.Int _ _) -> true
    | _ -> false
    in
    Printf.sprintf "(validate_nlist_constant_size_without_actions %s %s %s)" (if n_is_const then "true" else "false") (print_expr e) (print_validator p)
  | Validate_pair n1 p1 p2 ->
    Printf.sprintf "(validate_pair \"%s\" %s %s)" (print_ident n1) (print_validator p1) (print_validator p2)
  | Validate_dep_pair n1 p1 r (x, p2) ->
    Printf.sprintf "(validate_dep_pair \"%s\" %s %s (fun %s -> %s))"
      (print_ident n1)
      (print_validator p1)
      (print_reader r)
      (print_ident x)
      (print_validator p2)
  | Validate_dep_pair_with_refinement p1_is_constant_size_without_actions n1 f1 p1 r (x, e) (y, p2) ->
    Printf.sprintf "(validate_dep_pair_with_refinement %s \"%s\" %s %s %s (fun %s -> %s) (fun %s -> %s))"
      (if p1_is_constant_size_without_actions then "true" else "false")
      (print_ident n1)
      (print_ident f1)
      (print_validator p1)
      (print_reader r)
      (print_ident x)
      (print_expr e)
      (print_ident y)
      (print_validator p2)
  | Validate_dep_pair_with_action p1 r (x, a) (y, p2) ->
    Printf.sprintf "(validate_dep_pair_with_action %s %s (fun %s -> %s) (fun %s -> %s))"
      (print_validator p1)
      (print_reader r)
      (print_ident x)
      (print_action a)
      (print_ident y)
      (print_validator p2)
  | Validate_dep_pair_with_refinement_and_action p1_is_constant_size_without_actions n1 f1 p1 r (x, e) (y, a) (z, p2)  ->
    Printf.sprintf "(validate_dep_pair_with_refinement_and_action %s \"%s\" %s %s %s (fun %s -> %s) (fun %s -> %s) (fun %s -> %s))"
      (if p1_is_constant_size_without_actions then "true" else "false")
      (print_ident n1)
      (print_ident f1)
      (print_validator p1)
      (print_reader r)
      (print_ident x)
      (print_expr e)
      (print_ident y)
      (print_action a)
      (print_ident z)
      (print_validator p2)
  | Validate_map p1 (x, e) ->
    Printf.sprintf "(%s `validate_map` (fun %s -> %s))" (print_validator p1) (print_ident x) (print_expr e)
  | Validate_refinement n1 p1 r (x, e) ->
    begin
      if is_unit_validator p1
      then Printf.sprintf "(validate_unit_refinement (fun %s -> %s) \"checking precondition\")"
                          (print_ident x)
                          (print_expr e)
      else Printf.sprintf "(validate_filter \"%s\" %s %s (fun %s -> %s)
                                            \"reading field value\" \"checking constraint\")"
                          (print_ident n1)
                          (print_validator p1)
                          (print_reader r)
                          (print_ident x)
                          (print_expr e)
    end
  | Validate_refinement_with_action n1 p1 r (x, e) (y, a) ->
    Printf.sprintf "(validate_filter_with_action \"%s\" %s %s (fun %s -> %s)
                                            \"reading field value\" \"checking constraint\"
                                            (fun %s -> %s))"
                          (print_ident n1)
                          (print_validator p1)
                          (print_reader r)
                          (print_ident x)
                          (print_expr e)
                          (print_ident y)
                          (print_action a)
  | Validate_with_action name v a ->
    Printf.sprintf "(validate_with_success_action \"%s\" %s %s)"
      (print_ident name)
      (print_validator v)
      (print_action a)
  | Validate_with_dep_action n v r (x, a) ->
    Printf.sprintf "(validate_with_dep_action \"%s\" %s %s (fun %s -> %s))"
      (print_ident n)
      (print_validator v)
      (print_reader r)
      (print_ident x)
      (print_action a)
  | Validate_weaken_left p1 k ->
    Printf.sprintf "(validate_weaken_left %s _)" (print_validator p1) // (print_kind k)
  | Validate_weaken_right p1 k ->
    Printf.sprintf "(validate_weaken_right %s _)" (print_validator p1) // (print_kind k)
  | Validate_if_else e v1 v2 ->
    Printf.sprintf "(validate_ite %s (fun _ -> %s) (fun _ -> %s) (fun _ -> %s) (fun _ -> %s))"
      (print_expr e)
      (print_parser v1.v_parser)
      (print_validator v1)
      (print_parser v2.v_parser)
      (print_validator v2)
  | Validate_impos -> "(validate_impos())"
  | Validate_with_error fn v ->
    Printf.sprintf "(validate_with_error %s %s)" (print_ident fn) (print_validator v)
  | Validate_with_comment v c ->
    let c = String.concat "\n" c in
    Printf.sprintf "(validate_with_comment \"%s\" %s)"
      c
      (print_validator v)

let print_typedef_name (tdn:typedef_name) =
  Printf.sprintf "%s %s"
    (print_ident tdn.td_name)
    (String.concat " "
      (List.Tot.map (fun (id, t) -> Printf.sprintf "(%s:%s)" (print_ident id) (print_typ t)) tdn.td_params))

let print_typedef_typ (tdn:typedef_name) =
  Printf.sprintf "%s %s"
    (print_ident tdn.td_name)
    (String.concat " "
      (List.Tot.map (fun (id, t) -> (print_ident id)) tdn.td_params))

let print_typedef_body (b:typedef_body) =
  match b with
  | TD_abbrev t -> print_typ t
  | TD_struct fields ->
    let print_field (sf:field) : Tot string =
        Printf.sprintf "%s : %s%s%s"
          (print_ident sf.sf_ident)
          (print_typ sf.sf_typ)
          (if sf.sf_dependence then " (*dep*)" else "")
          (match sf.sf_field_number with | None -> "" | Some n -> Printf.sprintf "(* %d *)" n)
    in
    let fields = String.concat ";\n" (List.Tot.map print_field fields) in
    Printf.sprintf "{\n%s\n}" fields

let print_typedef_actions_inv_and_fp (td:type_decl) =
    let pointers =
      List.Tot.filter (fun (x, t) -> T_pointer? t) td.decl_name.td_params
    in
    let inv =
      List.Tot.fold_right
        (fun (x, t) out ->
          Printf.sprintf "((ptr_inv %s) `conj_inv` %s)"
                         (print_ident x)
                         out)
        pointers
        "true_inv"
    in
    let fp =
      List.Tot.fold_right
        (fun (x, t) out ->
          Printf.sprintf "(eloc_union (ptr_loc %s) %s)"
                         (print_ident x)
                         out)
        pointers
        "eloc_none"
    in
    inv, fp

let print_decl (d:decl) : Tot string =
  let print_comments cs =
    match cs with
    | [] -> ""
    | _ ->
      let c = String.concat "\\n\\\n" cs in
      Printf.sprintf " (Comment \"%s\")" c
  in
  let print_attributes entrypoint attrs =
    match attrs.comments with
    | [] ->
      if entrypoint
      then ""
      else if attrs.should_inline
      then "inline_for_extraction noextract\n"
      else "[@ (CInline)]\n"
    | cs ->
      let c = String.concat "\\n\\\n" cs in
      Printf.sprintf "[@ %s %s]\n%s"
        (print_comments cs)
        (if not entrypoint && not attrs.should_inline then "(CInline)" else "")
        (if attrs.should_inline then "inline_for_extraction\n" else "")
  in
  match fst d with
  | Definition (x, [], T_app ({Ast.v="field_id"}) _, Constant c) ->
    Printf.sprintf "[@(CMacro)%s]\nlet %s = %s <: Tot field_id by (FStar.Tactics.trivial())\n\n"
      (print_comments (snd d).comments)
      (print_ident x)
      (A.print_constant c)

  | Definition (x, [], t, Constant c) ->
    Printf.sprintf "[@(CMacro)%s]\nlet %s = %s <: Tot %s\n\n"
      (print_comments (snd d).comments)
      (print_ident x)
      (A.print_constant c)
      (print_typ t)

  | Definition (x, params, typ, expr) ->
    let x_ps = {
      td_name = x;
      td_params = params;
      td_entrypoint = false
    } in
    Printf.sprintf "%slet %s : %s = %s\n\n"
      (print_attributes false (snd d))
      (print_typedef_name x_ps)
      (print_typ typ)
      (print_expr expr)
  | Type_decl td ->
    Printf.sprintf "noextract\ninline_for_extraction\ntype %s = %s\n\n"
      (print_typedef_name td.decl_name)
      (print_typedef_body td.decl_typ)
    `strcat`
    Printf.sprintf "noextract\ninline_for_extraction\nlet kind_%s : parser_kind %s = %s\n\n"
      (print_ident td.decl_name.td_name)
      (string_of_bool td.decl_parser.p_kind.pk_nz)
      (print_kind td.decl_parser.p_kind)
    `strcat`
    Printf.sprintf "noextract\nlet parse_%s : parser (kind_%s) (%s) = %s\n\n"
      (print_typedef_name td.decl_name)
      (print_ident td.decl_name.td_name)
      (print_typedef_typ td.decl_name)
      (print_parser td.decl_parser)
    `strcat`
    (let inv, fp = print_typedef_actions_inv_and_fp td in
     Printf.sprintf "%slet validate_%s = validate_weaken_inv_loc _ _ %s <: Tot (validate_with_action_t (parse_%s) %s %s %b) by (weaken_tac())\n\n"
      (print_attributes td.decl_name.td_entrypoint (snd d))
      (print_typedef_name td.decl_name)
      (print_validator td.decl_validator)
      (print_typedef_typ td.decl_name)
      inv
      fp
      td.decl_validator.v_allow_reading)
    `strcat`
    (match td.decl_reader with
     | None -> ""
     | Some r ->
       Printf.sprintf "%sinline_for_extraction\nlet read_%s : leaf_reader (parse_%s) = %s\n\n"
         (if td.decl_name.td_entrypoint then "" else "noextract\n")
         (print_typedef_name td.decl_name)
         (print_typedef_typ td.decl_name)
         (print_reader r))


let print_decl_signature (d:decl) : Tot string =
  match fst d with
  | Definition _ -> ""
  | Type_decl td ->
    if not td.decl_name.td_entrypoint
    then ""
    else begin
      Printf.sprintf "noextract\ninline_for_extraction\nval %s : Type u#0\n\n"
        (print_typedef_name td.decl_name)
      `strcat`
      Printf.sprintf "noextract\ninline_for_extraction\nval kind_%s : parser_kind %s\n\n"
        (print_ident td.decl_name.td_name)
        (string_of_bool td.decl_parser.p_kind.pk_nz)
      `strcat`
      Printf.sprintf "noextract\nval parse_%s : parser (kind_%s) (%s)\n\n"
        (print_typedef_name td.decl_name)
        (print_ident td.decl_name.td_name)
        (print_typedef_typ td.decl_name)
      `strcat`
      (let inv, fp = print_typedef_actions_inv_and_fp td in
      Printf.sprintf "val validate_%s : validate_with_action_t (parse_%s) %s %s %b\n\n"
        (print_typedef_name td.decl_name)
        (print_typedef_typ td.decl_name)
        inv
        fp
        td.decl_validator.v_allow_reading)
     end


let print_decls (ds:list decl) =
  let decls =
  Printf.sprintf
    "module %s\n\
     open Prelude\n\
     open Actions\n\
     module B = LowStar.Buffer\n\
     #set-options \"--using_facts_from '* FStar Actions Prelude -FStar.Tactics -FStar.Reflection -LowParse'\"\n\
     %s"
     (Options.get_module_name())
     (String.concat "\n////////////////////////////////////////////////////////////////////////////////\n" (List.Tot.map print_decl ds))
  in
  decls

let print_decls_signature (ds:list decl) =
  let decls =
    Printf.sprintf
    "module %s\n\
     open Prelude\n\
     open Actions\n\
     module B = LowStar.Buffer\n\
     %s"
     (Options.get_module_name())
     (String.concat "\n" (List.Tot.map print_decl_signature ds))
  in
  // let dummy =
  //     "let retain (x:result) : Tot (FStar.UInt64.t & bool) = field_id_of_result x, result_is_error x"
  // in
  decls // ^ "\n" ^ dummy

let print_error_map () : ML (string & string & string) =
  let errs = Binding.all_nums() in
  let error_reasons =
    "static char* ErrorReasonOfResult (uint64_t code) {\n\t\
      switch (code) {\n\t\t\
        case 1: return \"generic error\";\n\t\t\
        case 2: return \"not enough data\";\n\t\t\
        case 3: return \"impossible\";\n\t\t\
        case 4: return \"list size not multiple of element size\";\n\t\t\
        case 5: return \"action failed\";\n\t\t\
        case 6: return \"constraint failed\";\n\t\t\
        default: return \"unspecified\";\n\t\
      }\n\
     }"
  in
  let struct_names =
    List.map
    (fun (kis: (A.field_num * option A.ident * string)) ->
      let k, i, s = kis in
      Printf.sprintf "case %d: return \"%s\";"
        k
        (match i with
         | None -> ""
         | Some i -> A.print_ident i))
    errs
 in
 let field_names =
    List.map
    (fun (kis: (A.field_num * option A.ident * string)) ->
      let k, i, s = kis in
      Printf.sprintf "case %d: return \"%s\";"
        k s)
    errs
 in
 let print_switch fname cases =
   Printf.sprintf
     "static char* %s(uint64_t err) {\n\t\
        switch (EverParseFieldIdOfResult(err)) {\n\t\t\
          %s \n\t\t\
          default: return \"\";\n\t\
       }\n\
      }\n"
      fname
      (String.concat "\n\t\t" cases)
 in
 error_reasons,
 print_switch "StructNameOfErr" struct_names,
 print_switch "FieldNameOfErr" field_names

#push-options "--z3rlimit_factor 4"
let rec print_as_c_type (t:typ) : Tot string =
    let open Ast in
    match t with
    | T_pointer t ->
          Printf.sprintf "%s*" (print_as_c_type t)
    | T_app {v="UINT32"} [] ->
          "uint32_t"
    | T_app {v="UINT64"} [] ->
          "uint64_t"
    | T_app {v=x} [] ->
          x
    | _ ->
         "__UNKNOWN__"

let pascal_case name : ML string =
  let chars = String.list_of_string name in
  let has_underscore = List.mem '_' chars in
  let keep, up, low = 0, 1, 2 in
  if has_underscore then
    let what_next : ref int = alloc up in
    let rewrite_char c : ML (list FStar.Char.char) =
      match c with
      | '_' ->
        what_next := up;
        []
      | c ->
        let c_next =
          let n = !what_next in
          if n = keep then c
          else if n = up then FStar.Char.uppercase c
          else FStar.Char.lowercase c
        in
        let _ =
          if Char.uppercase c = c
          then what_next := low
          else if Char.lowercase c = c
          then what_next := keep
        in
        [c_next]
    in
    let chars = List.collect rewrite_char (String.list_of_string name) in
    String.string_of_list chars
  else if String.length name = 0
  then name
  else String.uppercase (String.sub name 0 1) ^ String.sub name 1 (String.length name - 1)

let print_c_entry (ds:list decl) : ML (string & string) =
  let error_reasons, struct_name_map, field_name_map = print_error_map() in

  let print_one_validator (d:type_decl) : ML (string & string) =
    let print_params (ps:list param) : Tot string =
      let params =
        String.concat
          ", "
          (List.Tot.map
            (fun (id, t) -> Printf.sprintf "%s %s" (print_as_c_type t) (print_ident id))
            ps)
       in
       match ps with
       | [] -> params
       | _ -> params ^ ", "
    in
    let wrapper_name =
      Printf.sprintf "%s_check_%s"
        (Options.get_module_name())
        (A.print_ident d.decl_name.td_name)
      |> pascal_case
    in
    let signature =
      Printf.sprintf "bool %s(%suint8_t *base, uint32_t len)"
       wrapper_name
       (print_params d.decl_name.td_params)
    in
    let validator_name =
       Printf.sprintf "%s_validate_%s"
         (Options.get_module_name())
         (print_ident d.decl_name.td_name)
       |> pascal_case
    in
    let impl =
      Printf.sprintf
      "%s {\n\t\
         InputBuffer s;\n\t\
         s.base = base;\n\t\
         s.len = len;\n\t\
         uint64_t result = %s(%s, 0);\n\t\
         if (EverParseResultIsError(result)) {\n\t\t\
           EverParseError(\n\t\
                  StructNameOfErr(result),\n\t\t\t\
                  FieldNameOfErr (result),\n\t\t\t\
                  ErrorReasonOfResult(result));\n\t\t\
           return false;\n\t\
         }\n\t\
         return true;\n\
       }"
       signature
       validator_name
       (((List.Tot.map (fun (id, _) -> print_ident id) d.decl_name.td_params)@["s"]) |> String.concat ", ")
    in
    signature ^";",
    impl
  in
  let signatures, impls =
    List.split
      (List.collect
        (fun d ->
          match fst d with
          | Type_decl d ->
            if d.decl_name.td_entrypoint
            then [print_one_validator d]
            else []
          | _ -> [])
        ds)
  in
  let header =
    Printf.sprintf
      "#include \"%s.h\"\n\
       %s\n"
      (Options.get_module_name())
      (signatures |> String.concat "\n\n")
  in
  let impl =
    Printf.sprintf
      "#include \"EverParseError.h\"\n\
       #include \"EverParse.h\"\n\
       #include \"%s.h\"\n\
       %s\n\
       %s\n\
       %s\n\
       %s\n"
      (Options.get_module_name())
       error_reasons
      struct_name_map
      field_name_map
      (impls |> String.concat "\n\n")
  in
  header,
  impl