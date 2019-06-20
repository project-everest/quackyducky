/* 
  This file was generated by KreMLin <https://github.com/FStarLang/kremlin>
  KreMLin invocation: krml -I ../../src/lowparse -skip-compilation -tmpdir ../unittests.snapshot -bundle LowParse.\* -drop FStar.Tactics.\* -drop FStar.Reflection.\* T10.fst T11.fst T11_z.fst T12.fst T12_z.fst T13.fst T13_x.fst T14.fst T14_x.fst T15_body.fst T15.fst T16.fst T16_x.fst T17.fst T17_x_a.fst T17_x_b.fst T18.fst T18_x_a.fst T18_x_b.fst T19.fst T1.fst T20.fst T21.fst T22_body_a.fst T22_body_b.fst T22.fst T23.fst T24.fst T24_y.fst T25_bpayload.fst T25.fst T25_payload.fst T26.fst T27.fst T28.fst T29.fst T2.fst T30.fst T31.fst T32.fst T33.fst T34.fst T35.fst T36.fst T3.fst T4.fst T5.fst T6.fst T6le.fst T7.fst T8.fst T8_z.fst T9_b.fst T9.fst Tag2.fst Tag.fst Tagle.fst -warn-error +9
  F* version: 74c6d2a5
  KreMLin version: 1bd260eb
 */

#include "kremlib.h"
#ifndef __T16_H
#define __T16_H

#include "LowParse.h"
#include "T16_x.h"


typedef struct T16_t16_s
{
  uint16_t len;
  T16_x_t16_x x;
}
T16_t16;

uint16_t T16___proj__Mkt16__item__len(T16_t16 projectee);

T16_x_t16_x T16___proj__Mkt16__item__x(T16_t16 projectee);

uint32_t T16_t16_validator(LowParse_Slice_slice input, uint32_t pos);

uint32_t T16_t16_jumper(LowParse_Slice_slice input, uint32_t pos);

uint32_t T16_accessor_t16_len(LowParse_Slice_slice input, uint32_t pos);

uint32_t T16_accessor_t16_x(LowParse_Slice_slice input, uint32_t pos);

#define __T16_H_DEFINED
#endif
