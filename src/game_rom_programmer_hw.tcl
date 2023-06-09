# TCL File Generated by Component Editor 18.1
# Mon May 01 21:49:27 CDT 2023
# DO NOT MODIFY


# 
# game_rom_programmer "game_rom_programmer" v1.0
# Xavier Routh 2023.05.01.21:49:27
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module game_rom_programmer
# 
set_module_property DESCRIPTION ""
set_module_property NAME game_rom_programmer
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP "ECE 385 Custom IPs"
set_module_property AUTHOR "Xavier Routh"
set_module_property DISPLAY_NAME game_rom_programmer
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL ROM_PRGMR
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file ROM_PRGMR.sv SYSTEM_VERILOG PATH ROM_PRGMR.sv TOP_LEVEL_FILE

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL ROM_PRGMR
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file ROM_PRGMR.sv SYSTEM_VERILOG PATH ROM_PRGMR.sv


# 
# parameters
# 


# 
# display items
# 


# 
# connection point avl_mm_slave
# 
add_interface avl_mm_slave avalon end
set_interface_property avl_mm_slave addressUnits WORDS
set_interface_property avl_mm_slave associatedClock clk
set_interface_property avl_mm_slave associatedReset reset
set_interface_property avl_mm_slave bitsPerSymbol 8
set_interface_property avl_mm_slave burstOnBurstBoundariesOnly false
set_interface_property avl_mm_slave burstcountUnits WORDS
set_interface_property avl_mm_slave explicitAddressSpan 0
set_interface_property avl_mm_slave holdTime 5
set_interface_property avl_mm_slave linewrapBursts false
set_interface_property avl_mm_slave maximumPendingReadTransactions 0
set_interface_property avl_mm_slave maximumPendingWriteTransactions 0
set_interface_property avl_mm_slave readLatency 0
set_interface_property avl_mm_slave readWaitStates 5
set_interface_property avl_mm_slave readWaitTime 5
set_interface_property avl_mm_slave setupTime 5
set_interface_property avl_mm_slave timingUnits Cycles
set_interface_property avl_mm_slave writeWaitStates 10
set_interface_property avl_mm_slave writeWaitTime 10
set_interface_property avl_mm_slave ENABLED true
set_interface_property avl_mm_slave EXPORT_OF ""
set_interface_property avl_mm_slave PORT_NAME_MAP ""
set_interface_property avl_mm_slave CMSIS_SVD_VARIABLES ""
set_interface_property avl_mm_slave SVD_ADDRESS_GROUP ""

add_interface_port avl_mm_slave AVL_ADDR address Input 2
add_interface_port avl_mm_slave AVL_WRITE write Input 1
add_interface_port avl_mm_slave AVL_WRITEDATA writedata Input 32
add_interface_port avl_mm_slave AVL_CS chipselect Input 1
set_interface_assignment avl_mm_slave embeddedsw.configuration.isFlash 0
set_interface_assignment avl_mm_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avl_mm_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avl_mm_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point game_rom_port
# 
add_interface game_rom_port conduit end
set_interface_property game_rom_port associatedClock clk
set_interface_property game_rom_port associatedReset reset
set_interface_property game_rom_port ENABLED true
set_interface_property game_rom_port EXPORT_OF ""
set_interface_property game_rom_port PORT_NAME_MAP ""
set_interface_property game_rom_port CMSIS_SVD_VARIABLES ""
set_interface_property game_rom_port SVD_ADDRESS_GROUP ""

add_interface_port game_rom_port ROM_DATA rom_data Output 8
add_interface_port game_rom_port PRG_ROM_WRITE prg_rom_write Output 1
add_interface_port game_rom_port ROM_ADDR rom_addr Output 16
add_interface_port game_rom_port CHR_ROM_WRITE chr_rom_write Output 1
add_interface_port game_rom_port mirroring_mode mirror Output 1
add_interface_port game_rom_port is_chr_ram chr_raml Output 1


# 
# connection point clk
# 
add_interface clk clock end
set_interface_property clk clockRate 50000000
set_interface_property clk ENABLED true
set_interface_property clk EXPORT_OF ""
set_interface_property clk PORT_NAME_MAP ""
set_interface_property clk CMSIS_SVD_VARIABLES ""
set_interface_property clk SVD_ADDRESS_GROUP ""

add_interface_port clk CLK clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clk
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset RESET reset Input 1

