#ifndef __ROM_PRGMR_H_
#define __ROM_PRGMR_H_

#include <alt_types.h>
#include "system.h"

struct ROM_PROGRAMMER_STRUCT {
	alt_u32 rom;
};

static volatile struct ROM_PROGRAMMER_STRUCT* rom_programmer = GAME_ROM_PROGRAMMER_0_BASE;

void write_prg_rom(alt_u16 address, alt_u8 data) {
	rom_programmer->rom = 0x80000000 | ((address) | (data << (16)));
}

void write_chr_rom(alt_u16 address, alt_u8 data) {
	rom_programmer->rom = 0x00000000 | ((address) | (data << (16)));
}

#endif /* __ROM_PRGMR_H_ */