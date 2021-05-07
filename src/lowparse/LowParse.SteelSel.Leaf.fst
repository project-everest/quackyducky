module LowParse.SteelSel.Leaf
include LowParse.SteelSel.VParse

(* Leaf readers and writers *)

module S = Steel.Memory
module SE = Steel.SelEffect
module SEA = Steel.SelEffect.Atomic
module A = Steel.SelArray
module AP = Steel.SelArrayPtr

let leaf_reader
  (#k: parser_kind)
  (#t: Type)
  (p: parser k t)
: Tot Type0
= (src: byte_array) ->
  SE.SteelSel t
    (vparse p src)
    (fun _ -> vparse p src)
    (fun _ -> True)
    (fun h res h' ->
      let s = h (vparse p src) in
      h' (vparse p src) == s /\
      res == s.contents
    )

let exact_serializer
  (#k: parser_kind)
  (#t: Type)
  (#p: parser k t)
  (s: serializer p)
: Tot Type0
= (dst: byte_array) ->
  (x: t) ->
  SE.SteelSel unit
    (AP.varrayptr dst)
    (fun _ -> AP.varrayptr dst)
    (requires (fun h -> A.length (h (AP.varrayptr dst)).AP.array == Seq.length (serialize s x)))
    (ensures (fun h _ h' ->
      let d = h (AP.varrayptr dst) in
      let d' = h' (AP.varrayptr dst) in
      d'.AP.array == d.AP.array /\
      d'.AP.contents == serialize s x
    ))

let write_exact
  (#k: parser_kind)
  (#t: Type)
  (#p: parser k t)
  (#s: serializer p)
  (w: exact_serializer s)
  (dst: byte_array)
  (x: t)
: SE.SteelSel unit
    (AP.varrayptr dst)
    (fun _ -> vparse p dst)
    (requires (fun h -> A.length (h (AP.varrayptr dst)).AP.array == Seq.length (serialize s x)))
    (ensures (fun h _ h' ->
      let d = h (AP.varrayptr dst) in
      let d' = h' (vparse p dst) in
      d'.array == d.AP.array /\
      d'.contents == x
    ))
= w dst x;
  intro_vparse p dst