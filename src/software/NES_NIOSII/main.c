/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include "system.h"
#include <stdlib.h>
#include <alt_types.h>
#include "nestest.h"
#include "rom_programmer.h"

int main()
{
  printf("Hello from Nios II!\n");

  printf("Beginning Programming \n");
  // Format is 0x00[DATA (2 Bytes) ][ADDR (4 Bytes)];
  /**
   * $FFFA�$FFFB = NMI vector
   * $FFFC�$FFFD = Reset vector
   * $FFFE�$FFFF = IRQ/BRK vector
   */


  // Write Program Rom
  for (int i = 0; i < prg_rom_size; i++) {
	  // Write BB to $C000 to $C000 + i
	  alt_u8 bytes = prg_rom_data[i];
	  // Write Data
	  write_prg_rom(0xC000 + i, bytes);
	  write_prg_rom(0x8000 + i, bytes);

  }


  for (int i = 0; i < 640; i++) {
	  usleep(5000);
	  printf("%X ", i);
	  write_chr_rom(0x1000, i * 1);
  }



  rom_programmer->rom = 0x00AAFFFA;
  rom_programmer->rom = 0x00AAFFFB;

  // Reset Vector
  rom_programmer->rom = 0x8000FFFC; // Lower part of address
  rom_programmer->rom = 0x80C0FFFD; // Higher part of address

  rom_programmer->rom = 0x00AAFFFE;
  rom_programmer->rom = 0x00AAFFFF;

  printf("Done Programming \n");


  return 0;
}
