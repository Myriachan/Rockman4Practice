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

// Copy the second half of Rockman's sprite block twice.
// Each one gets different sprites replaced.
// Copy Rockman's main sprite block as the first 2 KB.
incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10, $800


// Convenient constants.
define sprite_tile_0 $60
define sprite_tile_1 $61
define sprite_tile_2 $62
define sprite_tile_3 $63
define sprite_tile_4 $64
define sprite_tile_5 $65
define sprite_tile_6 $66
define sprite_tile_7 $67
define sprite_tile_8 $68
define sprite_tile_9 $69
define sprite_tile_apostrophe $6A


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


// NMI hook.  I copied the Rockman 3 practice ROM's hook code.
{savepc}
	{reorg $3E, $C0ED}
	jmp nmi_hook
{loadpc}
nmi_hook:
	// First deleted instruction.
	inc.b $92

	// Increment frame counter.
	inc.w current_time_frames
	lda.w current_time_frames
	cmp.b #60
	bne .no_carry
	inc.w current_time_seconds
	lda.b #0
	sta.w current_time_frames
.no_carry:

	// Second deleted instruction.
	ldx.b #$FF
	jmp $C0F1


// Called when loading a level, right before READY appears.
// Initialize the frame timer here.
{savepc}
	{reorg $3E, $C642}
	jmp init_level_hook
{loadpc}
init_level_hook:
	// Clear the timers.
	lda.b #0
	sta.w current_time_seconds
	sta.w current_time_frames
	sta.w last_time_timer
	// Deleted code (creates Rockman object?).
	lda.b #1
	sta.w $0300
	jmp $C647



// Hook the OAM clear code during various points.
{savepc}
	// Called during normal operation.
	{reorg $3E, $C7B8}
	jsr oam_hook_normal
	// Called during vertical screen transitions.
	{reorg $3E, $CE52}
	jsr oam_hook_transition
{loadpc}

oam_hook_normal:
	// Set normal CHR-RAM mode.
	lda.b #3
	ldx.b #$45
	sta.w $8000
	stx.w $8001
	// Copy timer.  When we stop executing, that's the value to display.
	// Technically, this should be a loop in case NMI increments during the
	// middle here, but that is *extremely* unlikely to cause a problem.
//.latch_loop:
	lda.w current_time_frames
	sta.w last_time_frames
	ldx.w current_time_seconds
	stx.w last_time_seconds
	//cmp.w current_time_frames
	//bne .latch_loop
	jmp $C421

oam_hook_transition:
	// Call original function.
	jsr $C421

	// Switch to our CHR-ROM bank.
	lda.b #3
	ldx.b #$01
	sta.w $8000
	stx.w $8001

	// Zero current time while we're in this function.  Write frames before
	// seconds to prevent NMI doing a carry (only one NMI can occur here).
	lda.b #0
	sta.w current_time_frames
	sta.w current_time_seconds

	// Build the sprite records for the time display.

	// This layout copies the Rockman 3 practice ROM.
	// Y coordinate.
	lda.b #16
	sta.w $0204
	sta.w $0208
	sta.w $020C
	sta.w $0210
	sta.w $0214

	// Attributes/palette.
	lda.b #%00000001
	sta.w $0206
	sta.w $020A
	sta.w $020E
	sta.w $0212
	sta.w $0216

	// X coordinate.
	lda.b #208 + (8 * 0)
	sta.w $0207
	lda.b #208 + (8 * 1)
	sta.w $020B
	lda.b #208 + (8 * 2)
	sta.w $020F
	lda.b #208 + (8 * 3)
	sta.w $0213
	lda.b #208 + (8 * 4)
	sta.w $0217

	// Tile ID.
	lda.b #{sprite_tile_apostrophe}
	sta.w $0205
	sta.w $0209
	sta.w $020D
	sta.w $0211
	sta.w $0215

	// This is supposed to point to the next available slot in the OAM buffer.
	lda.b #$18
	sta.b $97

	// Done.
	rts


//// Called when a horizontal screen transition occurs.
//{savepc}
//	{reorg $3E, $CAFF}
//	jmp transition_horizontal
//{loadpc}
//transition_horizontal:
//	// Number of frames to show the timer.
//	lda.b #60
//	jsr transition_shared
//	// Deleted code.
//	lda.b $2B
//	and.b #$0F
//	jmp $CB03
//
//
//// Shared transition code.  A is how many frames to show the timer.
//transition_shared:
//	// Display timer.
//	sta.w last_time_timer
//	lda.w current_time_seconds
//	sta.w last_time_seconds
//	lda.w current_time_frames
//	sta.w last_time_frames
//	rts
//
//
//// OAM hook, where we take over.
//// This is pretty much a copy of the Rockman 3 practice ROM's oam_hook.
//{savepc}
//	//{reorg $3E, $C7B8}
//	{reorg $3E, $CE52}
//	jsr oam_hook
//{loadpc}
//oam_hook:
//	// Call original function here.  It clears OAM, rather conveniently.
//	jsr $C421
//
//	// Is the timer still being displayed?
//	lda.w last_time_timer
//	bne .show
//	// Not displaying timer.
//	rts
//
//.show:
//	// Tick down how many frames to show the timer.
//	dec.w last_time_timer
//	bne .not_done
//
//	// Restore the CHR-RAM bank.
//	ldx.b #$45
//	bne .done_continue    // unconditional branch
//.not_done:
//	// Swap in our custom CHR-ROM bank.
//	ldx.b #$01
//.done_continue:
//	lda.b #3
//	sta.w $8000
//	stx.w $8001
//
//	// Zero the current time while we are displaying the timer.  This way,
//	// it'll start counting again from zero.
//	// NOTE: Write frames first, so that NMI won't accidentally carry into the
//	// seconds after we zero it if we're unlucky and the interrupt occurs
//	// between our writes here.
//	lda.b #0
//	sta.w current_time_frames
//	sta.w current_time_seconds
//	rts


// Lookup table to convert a binary value to decimal digits' sprite values.
number_table:
incsrc "numbertable.asm"


// RAM variables.  Designed similarly to the Rockman 3 practice ROM.

// Number of seconds and frames that've elapsed since last screen transition.
current_time_seconds:
	db 0
current_time_frames:
	db 0
// Number of frames to show the last room's time.
last_time_timer:
	db 0
// Number of seconds and frames we're displaying.
last_time_seconds:
	db 0
last_time_frames:
	db 0

// Current setting desired for CHR region 1400-17FF (MMC3 bank register 3).
desired_mmc3_bank3:
	db $45    // default to CHR-RAM

// Temporary memory.
temp1:
	db 0
temp2:
	db 0


{warnpc $8000}
