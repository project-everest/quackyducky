/* 
  This file was generated by KreMLin <https://github.com/FStarLang/kremlin>
  KreMLin invocation: krml -I ../../src/lowparse -skip-compilation -tmpdir ../unittests.snapshot -bundle LowParse.\* -drop FStar.Tactics.\* -drop FStar.Reflection.\* T10.fst T11.fst T11_z.fst T12.fst T12_z.fst T13.fst T13_x.fst T14.fst T14_x.fst T15_body.fst T15.fst T16.fst T16_x.fst T17.fst T17_x_a.fst T17_x_b.fst T18.fst T18_x_a.fst T18_x_b.fst T19.fst T1.fst T20.fst T21.fst T22_body_a.fst T22_body_b.fst T22.fst T23.fst T24.fst T24_y.fst T25_bpayload.fst T25.fst T25_payload.fst T26.fst T27.fst T28.fst T29.fst T2.fst T30.fst T31.fst T32.fst T33.fst T34.fst T35.fst T36.fst T3.fst T4.fst T5.fst T6.fst T6le.fst T7.fst T8.fst T8_z.fst T9_b.fst T9.fst Tag2.fst Tag.fst Tagle.fst -warn-error +9
  F* version: 74c6d2a5
  KreMLin version: 1bd260eb
 */

#include "T35.h"

uint32_t T35_t35_validator(LowParse_Slice_slice input, uint32_t pos)
{
  uint32_t
  n1 = LowParse_Low_BCVLI_validate_bounded_bcvli_((uint32_t)12U, (uint32_t)131072U, input, pos);
  if (LOWPARSE_LOW_BASE_VALIDATOR_MAX_LENGTH < n1)
    return n1;
  else
  {
    uint32_t len1 = LowParse_Low_BCVLI_read_bcvli(input, pos);
    if (input.len - n1 < len1)
      return LOWPARSE_LOW_BASE_VALIDATOR_ERROR_NOT_ENOUGH_DATA;
    else
    {
      uint32_t pos_ = n1 + len1;
      if (LOWPARSE_LOW_BASE_VALIDATOR_MAX_LENGTH < pos_)
        if (pos_ == LOWPARSE_LOW_BASE_VALIDATOR_ERROR_NOT_ENOUGH_DATA)
          return LOWPARSE_LOW_BASE_VALIDATOR_ERROR_GENERIC;
        else
          return pos_;
      else
        return pos_;
    }
  }
}

uint32_t T35_t35_jumper(LowParse_Slice_slice input, uint32_t pos)
{
  uint32_t n1 = LowParse_Low_BCVLI_jump_bcvli(input, pos);
  uint32_t len1 = LowParse_Low_BCVLI_read_bcvli(input, pos);
  return n1 + len1;
}

