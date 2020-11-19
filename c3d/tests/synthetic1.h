// Some constants explicitly in u32
enum
[[
  everparse::process(0)
]] {
  V2 = 0x00000002ul,
  V3 = 3ul,
  V4 = 0x00000004ul,
  V5 = 0x5ul,
  V6 = 0x00000006ul,
  V7 = 0x00000007ul,
  V8 = 0x00000008ul,
  V9 = 0x000009ul,
};

typedef struct { char dummy[0]; } unit;

// Some typedefs
typedef UINT32 UINT32_Alias1     [[everparse::process(1)]]     ;
typedef UINT32 UINT32_Alias2     [[everparse::process(1)]]     ;
typedef UINT32 UINT32_Alias3     [[everparse::process(1)]]     ;
typedef UINT32 UINT32_Alias4     [[everparse::process(1)]]     ;
typedef UINT32 UINT32_Alias5     [[everparse::process(1)]]     ;
typedef UINT32 ULONG             [[everparse::process(1)]]     ;
typedef UINT64 ULONG64;

//Struct with a where clause and sizeof
typedef struct [[
  everparse::process(0),
  everparse::parameter(UINT32 Len),
  everparse::where(Len == sizeof(this))
]] _STRUCT_1
{
  UINT32_Alias1 f1;
  UINT32        f2;
  UINT32        f3;
  UINT32        f4;
} STRUCT_1;

// Struct with where clause
// -- Field dependency
// -- instantiation of parameterized type
// -- unfolding type alias
typedef struct [[
  everparse::process(0),
  everparse::parameter(UINT32 Len),
  everparse::where (Len == sizeof(this))
]] _STRUCT_2
{
  UINT32_Alias3   len  [[everparse::constraint(true)]];
  STRUCT_1   field_1  [[everparse::with(len)]];
} STRUCT_2;

typedef struct [[
  everparse::process(0),
  everparse::parameter(UINT32 TotalLen)
]] _STRUCT_3
{
    UINT32_Alias1   f1;
    UINT32_Alias2   f2;
    ULONG           len
        [[everparse::constraint(true)]];
    UINT32          offset
        [[everparse::constraint(
            is_range_okay(TotalLen, offset, len) &&
            offset >= sizeof(this)
        )]];
    UINT32_Alias4   f4  [[everparse::constraint(f4 == 0)]];
    UINT8        buffer     [[everparse::byte_size(TotalLen - sizeof(this))]]   
                            [0];
} STRUCT_3;

enum
[[
  everparse::process(0)
]] {
  TAG_STRUCT_1 = 0,
  TAG_STRUCT_2 = 2,
  TAG_STRUCT_3 = 3,
};

typedef union [[
  everparse::process(0),
  everparse::switch(UINT32 Tag),
  everparse::parameter(UINT32 TotalLen)
]] _UNION_1
{
  STRUCT_1 struct1
    [[everparse::case(TAG_STRUCT_1),
      everparse::with(TotalLen)]];
  STRUCT_2 struct2
    [[everparse::case(TAG_STRUCT_2),
      everparse::with(TotalLen)]];
  STRUCT_3 struct3
    [[everparse::case(TAG_STRUCT_3),
      everparse::with(TotalLen)]];
  unit empty
    [[everparse::default]];
} UNION_1;

typedef struct [[
  everparse::process(0),
  everparse::entrypoint
]] _CONTAINER_1
{
  UINT32            Tag
    [[everparse::constraint(true)]];
  UINT32            MessageLength
    [[everparse::constraint(
       MessageLength >= sizeof(this)
       )]];
  UNION_1 union_ // FIXME: allow this to be unnamed
    [[everparse::with(Tag),
      everparse::with(MessageLength - sizeof(this))]];
} CONTAINER_1;

typedef struct [[
  everparse::process(0),
  everparse::entrypoint,
  everparse::parameter(UINT32 PLen),
  everparse::parameter(UINT32 HLen),
  everparse::mutable_parameter(UINT32 *offset1),
  everparse::mutable_parameter(UINT32 *len1),
  everparse::mutable_parameter(UINT32 *offset2),
  everparse::mutable_parameter(UINT32 *len2),
  everparse::where(sizeof(this) <= HLen && HLen <= PLen),
]] _HEADER {
  UINT32 Offset1
    [[everparse::constraint(sizeof(this) <= Offset1)]]
    [[everparse::on_success(^{
      *offset1 = Offset1;
      return true;
      })]]
    ;

  UINT32 Len1
    [[everparse::constraint(is_range_okay(PLen, Offset1, Len1))]]
    [[everparse::on_success(^{
      *len1 = Len1;
      return true;
      })]]
    ;

  UINT32 Dummy
    [[everparse::constraint(Dummy == 0)]]
    ;

  UINT32 Offset2
    /* no constraint */
    [[everparse::on_success(^{
      *offset2 = Offset2;
      return true;
      })]]
    ;

  UINT32 Len2
    [[everparse::constraint(
      /* coding an if-then as an expression */
      !(Offset2 != 0 || Len2 != 0) || (
        is_range_okay (HLen, Offset2, Len2) &&
        Offset2 >= sizeof(this) &&
        Offset2 + Len2 <= Offset2
      ))
    ]]
    [[everparse::on_success(^{
      *len2 = Len2;
      return true;
      })]]
    ;

  UINT32_Alias1 Dummy2
    [[everparse::constraint(Dummy2 == 0)]]
    ;

  UINT32_Alias1 Dummy3
    ;

} HEADER;

typedef struct [[
  everparse::process(0),
  everparse::parameter(UINT32 Bound)
]] _BITFIELD0
{
  ULONG bit_0:1;
  ULONG bit_1:1;
  ULONG bit_2:1;
  ULONG bit_3:1;
  ULONG bit_4:1;
  /* Attributes must appear before the bitwidth */
  ULONG bit_5_16
    [[everparse::constraint(bit_5_16 < 2000)]]
    : 11
    ;
  ULONG bit_16_26
    [[everparse::constraint(bit_16_26 < 2000 &&
                            bit_5_16 + bit_16_26 <= Bound)]]
    : 10
    ;
} BITFIELD0;

typedef struct [[
  everparse::process(0),
  everparse::parameter(UINT32 Bound)
]] _BITIFIELD1
{
  ULONG bit_0:1;
  ULONG bit_1:1;
  ULONG bit_2:1;
  ULONG bit_3:1;
  ULONG bit_4:1;
  ULONG bit_5_16
    [[everparse::constraint(bit_5_16 < 2000)]]
    : 11
    ;
  ULONG bit_16_26
    [[everparse::constraint(bit_16_26 < 2000 &&
                            bit_5_16 + bit_16_26 <= Bound)]]
    : 10
    ;
} BITFIELD1;

#define CONST1  91
#define CONST2  113

typedef struct [[
  everparse::process(0),
  everparse::parameter(UINT32 Bound)
]] _BITIFIELD2
{
  ULONG bit_0_8
    [[everparse::constraint(1)]] // Brings it into C3d scope
    :8
    ;
  ULONG bit_8_16
    [[everparse::constraint(bit_8_16 <= 220)]]
    :8
    ;

  ULONG bit_16_24
    [[everparse::constraint(bit_16_24 == 0
                              || (bit_16_24 * 4 + CONST1 + CONST2 <= Bound))]]
    :8
    ;
  ULONG bit_24_32
    [[everparse::constraint
              (bit_24_32 == 0 || (bit_24_32 * 4 + CONST1 + CONST2 <= Bound))]]
    [[everparse::constraint
              (bit_24_32 == 0 || (bit_16_24 * 4 + CONST1 + CONST2 + bit_0_8 <= Bound))]]
    :8
    ;
} BITFIELD2;

#define UNION2_CASE0 0
#define UNION2_CASE1 1
#define UNION2_CASE2 2
#define UNION2_CASE3 3
#define UNION2_CASE4 4
#define UNION2_CASE5 5
#define UNION2_CASE6 6
#define UNION2_CASE7 7
#define UNION2_CASE8 8
#define UNION2_CASE9 9
#define UNION2_CASE10 10
#define UNION2_CASE11 11
#define UNION2_CASE12 12

typedef union [[
  everparse::process(0),
  everparse::parameter(UINT32 Tag),
  everparse::switch(UINT32 Len),
  everparse::mutable_parameter(UINT32 *Out0),
  everparse::mutable_parameter(UINT32 *Out1),
  everparse::mutable_parameter(UINT32 *Out2),
]] _UNION2 {
  BITFIELD0 bf0
    [[everparse::case(UNION2_CASE0)]]
    [[everparse::with(Len)]]
    [[everparse::on_success(^{
      *Out0 = 42; // bf0; // GM: ill-typed?
      return true;
      })]]
    ;

  BITFIELD0 bf1
    [[everparse::case(UNION2_CASE1)]]
    [[everparse::with(Len)]]
    [[everparse::on_success(^{
      *Out1 = 42;
      return true;
      })]]
    ;

  BITFIELD0 bf2
    [[everparse::case(UNION2_CASE2)]]
    [[everparse::with(Len)]]
    [[everparse::on_success(^{
      *Out2 = 42;
      return true;
      })]]
    ;

} UNION2;
