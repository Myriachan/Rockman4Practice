// The assembler I'm using doesn't know 6502, hehe.
arch snes.cpu

// Macro to change where we are
macro reorg bank, address
	org $10 + ({bank} * $2000) + ({address} & $1FFF)
	base {address}
endmacro

// Allows going back and forth
define savepc push origin, base
define loadpc pull base, origin

// Warn if the current address is greater than the specified value.
macro warnpc n
	{#}:
	if {#} > {n}
		warning "warnpc assertion failure"
	endif
endmacro


// The first thing we do is build the base file.

// Replacement NES header.  The ROM is changed from 4 to 119 (TQROM) so that we can use
// CHR-ROM and CHR-RAM together.
define mapper_id 119
org 0
base 0
	db $4E, $45, $53, $1A                    // NES^Z magic value
	db $80000 / $4000                        // number of 16 KB PRG-ROM banks
	db 1                                     // number of 8 KB CHR-ROM banks
	db (({mapper_id} & $F) << 4) | %0000     // mapper low and flags
	db ({mapper_id} & $F0) | %1000           // mapper mid and NES 2.0 magic
	db (0 << 4) | ({mapper_id} >> 8)         // mapper high and submapper (none)
	db (0 << 4) | 0                          // high nibbles of bank counts
	db (0 << 4) | 7                          // 8192 bytes of non-battery-backed PRG-RAM
	db (0 << 4) | 7                          // 8192 bytes of non-battery-backed CHR-RAM
	db %00                                   // NTSC video mode, not PAL-compatible
	db 0                                     // standard home console PPU model
	db 0                                     // no special ROMs
	db 0     

// Original game.
incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10, $80000

// Space for our CHR-ROM.
incbin "zeros8kb.bin"


// We now go back and overwrite parts.

// Our main data block is in CHR-ROM, copied to PRG-RAM at boot.
{reorg $40, $6000}

// Copy Rockman's main sprite block as the first 2 KB.
incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10, $800


// Hook the reset sequence to load our code from CHR-ROM to PRG-RAM.
{savepc}
	// This is overwriting the RAM clear routine.
	{reorg $3F, $FE39}
boot_copy_hook:

	// Set the CHR banks to CHR-ROM.
	ldx.b #5
.bank_loop:
	stx.w $8000
	lda.w .chr_rom_bank_table, x
	sta.w $8001
	dex
	bpl .bank_loop

	// Copy CHR-ROM 0000-1FFF to PRG-RAM 6000-7FFF.
	// Enable PRG-RAM, and for writing.
	lda.b #%10000000
	sta.w $A001
	// PPU read address = 0.
	lda.b #0
	sta.w $2006
	sta.w $2006
	// $00 will contain the word address to write to.
	sta.b $00
	// Dummy PPU read.
	ldx.w $2007
	// Clear Y for the 256 iterations.
	tay
	// Bank to write to.
	ldx.b #$60
.copy_outer_loop:
	stx.b $01
.copy_inner_loop:
	lda.w $2007
	sta ($00), y
	iny
	bne .copy_inner_loop
	inx
	// When X goes from 7F to 80, we're done -> use BPL.
	bpl .copy_outer_loop
	// Scram.  Y must be zero here.
	jmp boot_continue

.chr_rom_bank_table:
	// MMC3 values to write to the first 6 MMC3 bank registers (CHR space).
	db $00, $02, $04, $05, $06, $07

	{warnpc $FE7F}
{loadpc}

// Continuation of init code.
boot_continue:
	// Copy the code we replaced to here.  It's relocatable.
	// Note that Y is already zero.
	incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10 + ($3F * $2000) + ($FE39 & $1FFF), $FE7F - $FE39
	// We now resume our regularly scheduled programming.
	jmp $FE7F


// Make the game switch to CHR-RAM like it expects.  We need to set the 40 bit
// of the original values.  (The code that reads this table is copied by the
// incbin above, but that's fine.)
{savepc}
	{reorg $3F, $FFAD}
	db $40, $42, $44, $45, $46, $47
{loadpc}
