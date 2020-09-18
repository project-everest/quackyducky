#include <stdint.h>

enum
  [[everparse::process(1)]]
{
	KIND_INT = 1,
};

enum
  [[everparse::process(1)]]
{
	KIND_CHAR = 2,
};

enum
  [[everparse::process(1)]]
Enum8 {
	  Enum8_1 = 0,
	  Enum8_2,
	  Enum8_3,
	  Enum8_100 = 0x64,
	  Enum8_101 = 101,
	  Enum8_103,
	  Enum8_104,
};
union
  [[everparse::process(1)]]
  [[everparse::entrypoint]]
  [[everparse::switch(uint32_t kind)]]
sum {
	uint32_t i [[everparse::case(KIND_INT)]];
	uint8_t c [[everparse::case(KIND_CHAR)]];
};