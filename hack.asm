// The assembler I'm using doesn't know 6502, hehe.
arch snes.cpu

// Macro to change where we are
macro reorg bank, address
	org $10 + (({bank}) * $2000) + (({address}) & $1FFF)
	base {address}
endmacro

// Allows going back and forth
define savepc push origin, base
define loadpc pull base, origin

// Warn if the current address is greater than the specified value.
macro warnpc n
	{#}:
	if {#} > ({n})
		warning "warnpc assertion failure"
	endif
endmacro


// Helpful addresses and constants.
define ram_zp_current_level $0022
define ram_zp_completed_stages $00A9
define ram_zp_2000_shadow $00FD
define rom_bank39_level_id_map $8860
define rom_play_sound $F6BE
define sound_choose $2A
define sound_move_cursor $2E
define sound_pause $30


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
incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10 + $400, $400
incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10 + $400, $400


{savepc}
// Replace certain tiles above with number sprites.
//
// We have two copies, because boss kills and deaths need the explosion
// animation, and screen transitions potentially need the climbing animation.
//
// In both cases, the sprites for Rockman shooting from a ladder and for the
// two small weapon refills are never necessary, for 7 sprites.

// Screen transition version:
// 4C -> apostrophe: Replace Rockman's face for shooting from a ladder.
{reorg $40, $6000 + (($4C - $40) * $10)}
incbin "numbersprites.bin", 12 * $10, $10
// 5A, 5B, 6A, 6B -> 0, 1, 2, 3: Replace Rockman's body for shooting from a ladder.
{reorg $40, $6000 + (($5A - $40) * $10)}
incbin "numbersprites.bin", 0 * $10, $10
{reorg $40, $6000 + (($5B - $40) * $10)}
incbin "numbersprites.bin", 1 * $10, $10
{reorg $40, $6000 + (($6A - $40) * $10)}
incbin "numbersprites.bin", 2 * $10, $10
{reorg $40, $6000 + (($6B - $40) * $10)}
incbin "numbersprites.bin", 3 * $10, $10
// 7E, 7F -> 4, 5: Replace small weapon refills.
{reorg $40, $6000 + (($7E - $40) * $10)}
incbin "numbersprites.bin", 4 * $10, $10
{reorg $40, $6000 + (($7F - $40) * $10)}
incbin "numbersprites.bin", 5 * $10, $10
// 60, 61, 62, 63 -> 6, 7, 8, 9: Replace explosion animation.
{reorg $40, $6000 + (($60 - $40) * $10)}
incbin "numbersprites.bin", 6 * $10, $10
{reorg $40, $6000 + (($61 - $40) * $10)}
incbin "numbersprites.bin", 7 * $10, $10
{reorg $40, $6000 + (($62 - $40) * $10)}
incbin "numbersprites.bin", 8 * $10, $10
{reorg $40, $6000 + (($63 - $40) * $10)}
incbin "numbersprites.bin", 9 * $10, $10

// Boss kill, death animation version:
// 4C -> apostrophe: Replace Rockman's face for shooting from a ladder.
{reorg $40, $6400 + (($4C - $40) * $10)}
incbin "numbersprites.bin", 12 * $10, $10
// 5A, 5B, 6A, 6B -> 0, 1, 2, 3: Replace Rockman's body for shooting from a ladder.
{reorg $40, $6400 + (($5A - $40) * $10)}
incbin "numbersprites.bin", 0 * $10, $10
{reorg $40, $6400 + (($5B - $40) * $10)}
incbin "numbersprites.bin", 1 * $10, $10
{reorg $40, $6400 + (($6A - $40) * $10)}
incbin "numbersprites.bin", 2 * $10, $10
{reorg $40, $6400 + (($6B - $40) * $10)}
incbin "numbersprites.bin", 3 * $10, $10
// 7E, 7F -> 4, 5: Replace small weapon refills.
{reorg $40, $6400 + (($7E - $40) * $10)}
incbin "numbersprites.bin", 4 * $10, $10
{reorg $40, $6400 + (($7F - $40) * $10)}
incbin "numbersprites.bin", 5 * $10, $10
// 4E, 4F, 5E, 5F -> 6, 7, 8, 9: Replace ladder climb animation.
{reorg $40, $6400 + (($4E - $40) * $10)}
incbin "numbersprites.bin", 6 * $10, $10
{reorg $40, $6400 + (($4F - $40) * $10)}
incbin "numbersprites.bin", 7 * $10, $10
{reorg $40, $6400 + (($5E - $40) * $10)}
incbin "numbersprites.bin", 8 * $10, $10
{reorg $40, $6400 + (($5F - $40) * $10)}
incbin "numbersprites.bin", 9 * $10, $10

{loadpc}

// Boss HP fills immediately
{savepc}
	{reorg $35, $A866}
	lda.b #$1C
	sta.b $BF
{loadpc}

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
	// Deleted code (creates Rockman object?).
	lda.b #1
	sta.w $0300
	jmp $C647


// Hook the OAM clear code during various points.
{savepc}
	// Called during normal operation.
	{reorg $3E, $C7B8}
	jsr oam_hook_normal
	// Called during horizontal screen transitions.
	{reorg $3E, $CBC3}
	jsr oam_hook_transition
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

	// Switch to the non-death CHR-ROM bank.
	lda.b #3
	ldx.b #$00
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

	// Tile IDs.
	// Apostrophe.
	lda.b #$4C
	sta.w $020D

	ldx.w last_time_seconds
	lda.w bcd_table, x
	tax
	and.b #$0F
	tay
	lda sprite_tile_table, y
	sta.w $0209
	txa
	lsr
	lsr
	lsr
	lsr
	tay
	lda sprite_tile_table, y
	sta.w $0205
	
	ldx.w last_time_frames
	lda.w bcd_table, x
	tax
	and.b #$0F
	tay
	lda sprite_tile_table, y
	sta.w $0215
	txa
	lsr
	lsr
	lsr
	lsr
	tay
	lda sprite_tile_table, y
	sta.w $0211

	// This is supposed to point to the next available slot in the OAM buffer.
	lda.b #$18
	sta.b $97

	// Done.
	rts


// Hook the code to load the stage select background.
{savepc}
	{reorg $39, $84AA}
	jsr show_screen_hook
{loadpc}
show_screen_hook:
	// Original function.
	// We need to do this first, because we overwrite what it puts into VRAM.
	jsr $DA05

	// Is this going to display stage select?
	lda.b $10
	cmp.b #2
	bne .not_stage_select
	lda.b $2A
	cmp.b #0
	bne .not_stage_select

	// Save X, which the target routine depends on.
	txa
	pha
	// Copy our alternate stage select screen to the second nametable.
	lda.w $2002   // reset latch
	lda.b #$28
	sta.w $2006
	lda.b #$00
	sta.w $2006
	tax
.loop_0:
	lda.w tilemap_second_level_select + $000, x
	sta.w $2007
	inx
	bne .loop_0
.loop_1:
	lda.w tilemap_second_level_select + $100, x
	sta.w $2007
	inx
	bne .loop_1
.loop_2:
	lda.w tilemap_second_level_select + $200, x
	sta.w $2007
	inx
	bne .loop_2
.loop_3:
	lda.w tilemap_second_level_select + $300, x
	sta.w $2007
	inx
	bne .loop_3

	// Overwrite "CAPCOM" from "CAPCOM PRESENTS" with the Dr. Wily logo,
	// since we don't need that bitmap anymore for stage select.
	lda.w $2002   // reset latch
	lda.b #($0000 + ($4A * $10)) >> 8
	sta.w $2006
	lda.b #($0000 + ($4A * $10)) & $FF
	sta.w $2006
	ldx.b #0
.loop_drwily:
	lda.w tiles_drwily_logo, x
	sta.w $2007
	inx
	cpx.b #tiles_drwily_logo.end - tiles_drwily_logo
	bne .loop_drwily

	// Restore saved X.
	pla
	tax

	// While we're here, clear out the completed stages list.
	lda.b #$00
	sta.b {ram_zp_completed_stages}
	sta.b {ram_zp_completed_stages} + 1

.not_stage_select:
	// Return to caller.
	rts


// Hack what happens when a level is chosen.
// We can delete a lot of code here.  Most of it is either checks we don't
// need, like special code for choosing Cossack.
{savepc}
	// Patch one byte of the original table: make middle option $FF.
	{reorg $39, {rom_bank39_level_id_map} + 4}
	db $FF

	// Where the code handling level choices goes.
	{reorg $39, $80C2}
level_select_choose:
	// Look up the level in the table based on where the cursor is.
	lda.b $10
	clc
	adc.b $11
	tay
	// Select which table to use based on whether Cossack/Wily list shows.
	lda.b {ram_zp_2000_shadow}
	and.b #%00000010
	beq .original_table
	lda .cossack_wily_table, y
	bne .table_continue          // no cossack table entries are zero -> branch always
.original_table:
	lda {rom_bank39_level_id_map}, y
.table_continue:

	// If the middle option was chosen, this value will be negative.
	bpl .not_middle

	// Middle option means to switch screens.  We switch screens by setting
	// the primary nametable to $2800 instead of $2000.
	lda.b {ram_zp_2000_shadow}
	eor.b #%00000010
	sta.b {ram_zp_2000_shadow}

	// If the shadow just became zero, restore the original sprites' Y locations.
	// Otherwise, hide the sprites.
	bne .hide_sprites
	// Reload the correct Y locations.
	ldx.b #0
	ldy.b #0
.show_sprites_loop:
	lda.w level_select_sprite_y_table, x
	sta $0218, y
	inx
	iny
	iny
	iny
	iny
	cpx.b #level_select_sprite_y_table.end - level_select_sprite_y_table
	bne .show_sprites_loop
	beq .sprites_done

.hide_sprites:
	// Hide the sprites.
	ldx.b #0
	ldy.b #0
	lda.b #$F8
.hide_sprites_loop:
	sta $0218, y
	inx
	iny
	iny
	iny
	iny
	cpx.b #level_select_sprite_y_table.end - level_select_sprite_y_table
	bne .hide_sprites_loop

.sprites_done:
	// Play the in-game menu/pause sound effect.
	lda.b #{sound_pause}
	jsr {rom_play_sound}
	// Return to select screen loop.
	jmp $80AD

.not_middle:
	// We skip a ton of useless stuff and skip to just loading the level.
	// An actual level was chosen.
	sta.b {ram_zp_current_level}

	// Play the "choose" sound effect.
	lda.b #{sound_choose}
	jsr {rom_play_sound}

	// I don't know what these do, but the original code does it here.
	lda.b #0
	sta.b $2A
	sta.b $24
	rts

.cossack_wily_table:
	// Map from the 9 cursor position to levels.
	db 8, 9, 10, 11, $FF, 12, 13, 14, 15

	// We can overwrite all the way through the Cossack castle intro code.
	{warnpc $8209}
{loadpc}


// Lookup table to convert a binary value to BCD.
bcd_table:
incsrc "bcdtable.asm"

// Mapping from numbers to sprite IDs.
sprite_tile_table:
	// Screen transition version:
	db $5A, $5B, $6A, $6B, $7E, $7F, $60, $61, $62, $63
	// Boss kill, death animation version:
	db $5A, $5B, $6A, $6B, $7E, $7F, $60, $61, $62, $63


// Tilemap layout for when the player hits select.
tilemap_second_level_select:
	incbin "stageselect-nametable.bin"

// Bitmap data for the Dr. Wily logo.
tiles_drwily_logo:
	incbin "drwily-logo.bin"
.end:

// The Y positions of the sprites on the stage select screen.
// We use this to restore when flipping "pages".
level_select_sprite_y_table:
	incbin "sprite-y-positions.bin"
.end:


// RAM variables.  Designed similarly to the Rockman 3 practice ROM.

// Number of seconds and frames that've elapsed since last screen transition.
current_time_seconds:
	db 0
current_time_frames:
	db 0
// Number of seconds and frames we're displaying.
last_time_seconds:
	db 0
last_time_frames:
	db 0


{warnpc $7FFF}
