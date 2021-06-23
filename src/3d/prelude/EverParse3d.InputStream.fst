module EverParse3d.InputStream

module U8 = FStar.UInt8
module U32 = FStar.UInt32
module HS = FStar.HyperStack
module HST = FStar.HyperStack.ST
module B = LowStar.Buffer

noextract
inline_for_extraction
class input_stream_inst (t: Type) : Type = {
  
  live: t -> HS.mem -> Tot prop;

  footprint: (x: t) -> Ghost B.loc
    (requires True)
    (ensures (fun y -> B.address_liveness_insensitive_locs `B.loc_includes` y));

  len_all: (x: t) -> GTot U32.t;

  get_all: (x: t) -> Ghost (Seq.seq U8.t)
    (requires True)
    (ensures (fun y -> Seq.length y == U32.v (len_all x)));

  get_remaining: (x: t) -> (h: HS.mem) -> Ghost (Seq.seq U8.t)
    (requires (live x h))
    (ensures (fun y -> Seq.length y <= U32.v (len_all x)));

  get_read: (x: t) -> (h: HS.mem) -> Ghost (Seq.seq U8.t)
    (requires (live x h))
    (ensures (fun y -> get_all x `Seq.equal` (y `Seq.append` get_remaining x h)));

  preserved:
    (x: t) ->
    (l: B.loc) ->
    (h: HS.mem) ->
    (h' : HS.mem) ->
    Lemma
    (requires (live x h /\ B.modifies l h h' /\ B.loc_disjoint (footprint x) l))
    (ensures (
      live x h' /\
      get_remaining x h' == get_remaining x h /\
      get_read x h' == get_read x h
    ))
    [SMTPatOr [
      [SMTPat (live x h); SMTPat (B.modifies l h h')];
      [SMTPat (live x h'); SMTPat (B.modifies l h h')];
      [SMTPat (get_remaining x h); SMTPat (B.modifies l h h')];
      [SMTPat (get_remaining x h'); SMTPat (B.modifies l h h')];
      [SMTPat (get_read x h); SMTPat (B.modifies l h h')];
      [SMTPat (get_read x h'); SMTPat (B.modifies l h h')];
    ]];

  has:
    (x: t) ->
    (n: U32.t) ->
    HST.Stack bool
    (requires (fun h -> live x h))
    (ensures (fun h res h' ->
      B.modifies B.loc_none h h' /\
      (res == true <==> Seq.length (get_remaining x h) >= U32.v n)
    ));

  read:
    (x: t) ->
    (n: U32.t) ->
    (dst: B.buffer U8.t) ->
    HST.Stack unit
    (requires (fun h -> live x h /\ B.live h dst /\ B.loc_disjoint (footprint x) (B.loc_buffer dst) /\ B.length dst == U32.v n /\ Seq.length (get_remaining x h) >= U32.v n))
    (ensures (fun h _ h' ->
      let s = get_remaining x h in
      B.modifies (B.loc_buffer dst `B.loc_union` footprint x) h h' /\
      B.as_seq h' dst == Seq.slice s 0 (U32.v n) /\
      live x h' /\
      get_remaining x h' == Seq.slice s (U32.v n) (Seq.length s)
    ));

  skip:
    (x: t) ->
    (n: U32.t) ->
    HST.Stack unit
    (requires (fun h -> live x h /\ Seq.length (get_remaining x h) >= U32.v n))
    (ensures (fun h _ h' ->
      let s = get_remaining x h in
      B.modifies (footprint x) h h' /\
      live x h' /\
      get_remaining x h' == Seq.slice s (U32.v n) (Seq.length s)
    ));

}

let length_all #t (#_: input_stream_inst t) (x: t) : GTot nat = U32.v (len_all x)