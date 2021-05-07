module LowParse.SteelSel.R2LOutput
include LowParse.Bytes

module S = Steel.Memory
module SE = Steel.SelEffect
module SEA = Steel.SelEffect.Atomic
module A = Steel.SelArray
module AP = Steel.SelArrayPtr
module U32 = FStar.UInt32

(* Right-to-left output buffer *)

val t: Type0

val vp_hp
  (x: t)
: Tot (S.slprop u#1)

val vp_sel
  (x: t)
: Tot (SE.selector (A.array byte) (vp_hp x))

[@SE.__steel_reduce__]
let vp' 
  (x: t)
: Tot SE.vprop'
= {
  SE.hp = vp_hp x;
  SE.t = A.array byte;
  SE.sel = vp_sel x;
}

[@SE.__steel_reduce__]
let vp
  (x: t)
: Tot SE.vprop
= SE.VUnit (vp' x)

val make
  (x: AP.t byte)
  (len: U32.t)
: SE.SteelSel t
    (AP.varrayptr x)
    (fun res -> vp res)
    (fun h -> A.len (h (AP.varrayptr x)).AP.array == len)
    (fun _ res h' ->
      A.len (h' (vp res)) == len
    )

let alloc
  (len: U32.t)
: SE.SteelSel t
    SE.emp
    (fun res -> vp res)
    (fun _ -> True)
    (fun _ res h' ->
      A.len (h' (vp res)) == len
    )
=
  let x = AP.alloc 0uy len in
  let _ = SEA.gget (AP.varrayptr x) in // FIXME: WHY WHY WHY?
  make x len

val len
  (x: t)
: SE.SteelSel U32.t
    (vp x)
    (fun _ -> vp x)
    (fun _ -> True)
    (fun h len h' ->
      h (vp x) == h' (vp x) /\
      A.len (h' (vp x)) == len
    )

val split
  (x: t)
  (len: U32.t)
: SE.SteelSel (AP.t byte)
    (vp x)
    (fun res -> vp x `SE.star` AP.varrayptr res)
    (fun h -> U32.v len <= A.length (h (vp x)))
    (fun h res h' ->
      let ar = (h' (AP.varrayptr res)).AP.array in
      A.merge_into (h' (vp x)) ar (h (vp x)) /\
      A.len ar == len
    )

val merge
  (x: t)
  (y: AP.t byte)
  (len: U32.t)
: SE.SteelSel unit
    (vp x `SE.star` AP.varrayptr y)
    (fun res -> vp x)
    (fun h ->
      let ar = (h (AP.varrayptr y)).AP.array in
      len == A.len ar /\
      A.adjacent (h (vp x)) ar
    )
    (fun h _ h' ->
      A.merge_into (h (vp x)) (h (AP.varrayptr y)).AP.array (h' (vp x))
    )

val free
  (x: t)
: SE.SteelSel unit
    (vp x)
    (fun _ -> SE.emp)
    (fun h -> A.freeable (h (vp x)))
    (fun _ _ _ -> True)