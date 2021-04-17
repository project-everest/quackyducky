module LowParse.SteelSel.VParse
include LowParse.Spec.Base

module S = Steel.Memory
module SE = Steel.SelEffect
module A = Steel.SelArray

let has_byte_repr
  (n: nat)
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (x: t)
: Tot prop
= supported_kind k /\
  (exists (b: Seq.lseq byte n) . is_byte_repr n p x b)

let select
  (n: Ghost.erased nat)
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (x: Seq.lseq byte n { valid n p x })
: GTot (select_t n p)
=
  let Some (y, _) = parse p x in
  y

let select_correct
  (n: Ghost.erased nat)
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (x: Seq.lseq byte n { valid n p x })
: Lemma
  (is_byte_repr n p (select n p x) x)
= ()

let vparse0
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (a: byte_array)
: Tot SE.vprop
= (A.varray a `SE.vrefine` valid (A.length a) p) `SE.vrewrite`  select (A.length a) p

let intro_vparse0
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (a: byte_array)
: SE.SteelSel unit
    (A.varray a)
    (fun _ -> vparse0 p a)
    (fun h ->
      valid (A.length a) p (h (A.varray a))
    )
    (fun h _ h' ->
      valid (A.length a) p (h (A.varray a)) /\
      is_byte_repr (A.length a) p (h' (vparse0 p a)) (h (A.varray a))
    )
=
  SE.intro_vrefine (A.varray a) (valid (A.length a) p);
  SE.intro_vrewrite (A.varray a `SE.vrefine` valid (A.length a) p) (select (A.length a) p);
  assert_norm ((A.varray a `SE.vrefine` valid (A.length a) p) `SE.vrewrite` select (A.length a) p == vparse0 p a);
  SE.change_equal_slprop ((A.varray a `SE.vrefine` valid (A.length a) p) `SE.vrewrite` select (A.length a) p) (vparse0 p a)

let select_recip
  (n: Ghost.erased nat)
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (y: select_t n p)
: GTot (x: Seq.lseq byte n { valid n p x })
= FStar.IndefiniteDescription.indefinite_description_ghost (Seq.lseq byte n) (is_byte_repr n p y)

let select_recip_correct
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (a: byte_array)
: Lemma
  (SE.elim_vrewrite_precond (A.varray a `SE.vrefine` valid (A.length a) p) (select (A.length a) p) (select_recip (A.length a) p))
= let n = A.length a in
  let f
    (x: Seq.lseq byte n { valid n p x })
  : Lemma
    (select_recip n p (select n p x) == x)
  =
    parse_injective p x (select_recip n p (select n p x))
  in
  Classical.forall_intro f

let change_equal_slprop (p q: SE.vprop)
  (sq: squash (p == q))
  : SE.SteelSel unit p (fun _ -> q) (fun _ -> True) (fun h0 _ h1 -> p == q /\ h1 q == h0 p)
= SE.change_equal_slprop p q

let elim_vparse0
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
  (a: byte_array)
: SE.SteelSel unit
    (vparse0 p a)
    (fun _ -> A.varray a)
    (fun _ -> True)
    (fun h _ h' ->
      valid (A.length a) p (h' (A.varray a)) /\
      is_byte_repr (A.length a) p (h (vparse0 p a)) (h' (A.varray a))
    )
=
  let sq : squash (vparse0 #k #t p a == (A.varray a `SE.vrefine` valid (A.length a) p) `SE.vrewrite` select (A.length a) p) =
    assert_norm (vparse0 #k #t p a == (A.varray a `SE.vrefine` valid (A.length a) p) `SE.vrewrite` select (A.length a) p)
  in
  change_equal_slprop (vparse0 #k #t p a)
    ((A.varray a `SE.vrefine` valid (A.length a) p) `SE.vrewrite` select (A.length a) p)
    sq;
  select_recip_correct p a;
  SE.elim_vrewrite (A.varray a `SE.vrefine` valid (A.length a) p) (select (A.length a) p) (select_recip (A.length a) p);
  let m1 = SE.get #(A.varray a `SE.vrefine` valid (A.length a) p) () in
  assert (valid (A.length a) p (m1 (A.varray a `SE.vrefine` valid (A.length a) p)));
  SE.elim_vrefine (A.varray a) (valid (A.length a) p)

let vparse_slprop
  #k #t p a
=
  SE.hp_of (vparse0 #k #t p a)

let vparse_sel
  #k #t p a
=
  fun m -> SE.sel_of (vparse0 p a) m

let intro_vparse
  #k #t p a
=
  intro_vparse0 p a;
  let m = SE.get #(vparse0 p a) () in
  let x : Ghost.erased (select_t (A.length a) p) = m (vparse0 p a) in
  SE.change_slprop
    (vparse0 p a)
    (vparse p a)
    x
    x
    (fun _ -> ())

let elim_vparse
  #k #t p a
=
  let m = SE.get #(vparse p a) () in
  let x : Ghost.erased (select_t (A.length a) p) = m (vparse p a) in
  SE.change_slprop
    (vparse p a)
    (vparse0 p a)
    x
    x
    (fun _ -> ());
  elim_vparse0 p a
