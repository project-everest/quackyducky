/* 
  This file was generated by KreMLin <https://github.com/FStarLang/kremlin>
  KreMLin invocation: krml -I ../../src/lowparse -skip-compilation -tmpdir ../unittests.snapshot -bundle LowParse.\* -drop FStar.Tactics.\* -drop FStar.Reflection.\* T10.fst T11.fst T11_z.fst T12.fst T12_z.fst T13.fst T13_x.fst T14.fst T14_x.fst T15_body.fst T15.fst T16.fst T16_x.fst T17.fst T17_x_a.fst T17_x_b.fst T18.fst T18_x_a.fst T18_x_b.fst T19.fst T1.fst T20.fst T21.fst T22_body_a.fst T22_body_b.fst T22.fst T23.fst T24.fst T24_y.fst T25_bpayload.fst T25.fst T25_payload.fst T26.fst T27.fst T28.fst T29.fst T2.fst T30.fst T31.fst T32.fst T33.fst T34.fst T35.fst T36.fst T3.fst T4.fst T5.fst T6.fst T6le.fst T7.fst T8.fst T8_z.fst T9_b.fst T9.fst Tag2.fst Tag.fst Tagle.fst -warn-error +9
  F* version: 74c6d2a5
  KreMLin version: 1bd260eb
 */

#include "T15.h"

FStar_Bytes_bytes T15___proj__Mkt15__item__start(T15_t15 projectee)
{
  return projectee.start;
}

T15_body_t15_body T15___proj__Mkt15__item__body(T15_t15 projectee)
{
  return projectee.body;
}

uint32_t T15_t15_validator(LowParse_Slice_slice input, uint32_t pos)
{
  uint32_t pos1 = T1_t1_validator(input, pos);
  if (pos1 > LOWPARSE_LOW_BASE_VALIDATOR_MAX_LENGTH)
    return pos1;
  else
    return T15_body_t15_body_validator(input, pos1);
}

uint32_t T15_t15_jumper(LowParse_Slice_slice input, uint32_t pos)
{
  return T15_body_t15_body_jumper(input, T1_t1_jumper(input, pos));
}

uint32_t T15_accessor_t15_start(LowParse_Slice_slice input, uint32_t pos)
{
  return pos;
}

uint32_t T15_accessor_t15_body(LowParse_Slice_slice input, uint32_t pos)
{
  uint32_t pos2 = pos;
  uint32_t pos21 = pos2;
  uint32_t res = T1_t1_jumper(input, pos21);
  uint32_t pos3 = res;
  uint32_t pos30 = pos3;
  return pos30;
}

