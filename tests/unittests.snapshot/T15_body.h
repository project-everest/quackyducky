/* 
  This file was generated by KreMLin <https://github.com/FStarLang/kremlin>
  KreMLin invocation: krml -I ../../src/lowparse -skip-compilation -tmpdir ../unittests.snapshot -bundle LowParse.\* -drop FStar.Tactics.\* -drop FStar.Reflection.\* T10.fst T11.fst T11_z.fst T12.fst T12_z.fst T13.fst T13_x.fst T14.fst T14_x.fst T15_body.fst T15.fst T16.fst T16_x.fst T17.fst T17_x_a.fst T17_x_b.fst T18.fst T18_x_a.fst T18_x_b.fst T19.fst T1.fst T20.fst T21.fst T22_body_a.fst T22_body_b.fst T22.fst T23.fst T24.fst T24_y.fst T25_bpayload.fst T25.fst T25_payload.fst T26.fst T27.fst T28.fst T29.fst T2.fst T30.fst T31.fst T32.fst T33.fst T34.fst T35.fst T36.fst T3.fst T4.fst T5.fst T6.fst T6le.fst T7.fst T8.fst T8_z.fst T9_b.fst T9.fst Tag2.fst Tag.fst Tagle.fst -warn-error +9
  F* version: 74c6d2a5
  KreMLin version: 1bd260eb
 */

#include "kremlib.h"
#ifndef __T15_body_H
#define __T15_body_H

#include "LowParse.h"
#include "Tag2.h"


#define T15_body_Body_x 0
#define T15_body_Body_y 1
#define T15_body_Body_w 2
#define T15_body_Body_v 3
#define T15_body_Body_t 4
#define T15_body_Body_z 5
#define T15_body_Body_Unknown_tag2 6

typedef uint8_t T15_body_t15_body_tags;

typedef struct T15_body_t15_body_s
{
  T15_body_t15_body_tags tag;
  union {
    uint16_t case_Body_x;
    uint32_t case_Body_y;
    uint8_t case_Body_Unknown_tag2;
  }
  ;
}
T15_body_t15_body;

bool T15_body_uu___is_Body_x(T15_body_t15_body projectee);

uint16_t T15_body___proj__Body_x__item___0(T15_body_t15_body projectee);

bool T15_body_uu___is_Body_y(T15_body_t15_body projectee);

uint32_t T15_body___proj__Body_y__item___0(T15_body_t15_body projectee);

bool T15_body_uu___is_Body_w(T15_body_t15_body projectee);

bool T15_body_uu___is_Body_v(T15_body_t15_body projectee);

bool T15_body_uu___is_Body_t(T15_body_t15_body projectee);

bool T15_body_uu___is_Body_z(T15_body_t15_body projectee);

bool T15_body_uu___is_Body_Unknown_tag2(T15_body_t15_body projectee);

uint8_t T15_body___proj__Body_Unknown_tag2__item__v(T15_body_t15_body projectee);

Tag2_tag2 T15_body_tag_of_t15_body(T15_body_t15_body x);

uint32_t T15_body_t15_body_validator(LowParse_Slice_slice input, uint32_t pos);

uint32_t T15_body_t15_body_jumper(LowParse_Slice_slice input, uint32_t pos);

uint32_t T15_body_t15_body_accessor_x(LowParse_Slice_slice input, uint32_t pos);

uint32_t T15_body_t15_body_accessor_y(LowParse_Slice_slice input, uint32_t pos);

#define __T15_body_H_DEFINED
#endif
