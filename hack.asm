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
define ram_zp_controller1_new $0014
define ram_zp_current_level $0022
define ram_zp_rockman_state $0030
define ram_zp_lives $00A1
define ram_zp_etanks $00A2
define ram_zp_completed_stages $00A9
define ram_zp_energy $00B0
define ram_zp_request_8000_bank $00F5
define ram_zp_request_A000_bank $00F6
define ram_zp_2000_shadow_1 $00FD
define ram_zp_2000_shadow_2 $00FF
define rom_bank39_level_id_map $8860
define rom_force_blank_on $C369
define rom_force_blank_off $C373
define rom_play_sound $F6BE
define rom_coroutine_yield $FF1C
define rom_prg_bank_switch $FF37
define sound_choose $2A
define sound_move_cursor $2E
define sound_pause $30

define current_time_seconds $05D0
define current_time_frames $05D1
define last_time_seconds $05D2
define last_time_frames $05D3
define sprite_tile_select $05D4


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
	db (0 << 4) | 0                          // 0 bytes of non-battery-backed PRG-RAM
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


// Move the reset routine out of the way in order make some space.
{savepc}
	// The raw beginning of reset.
	{reorg $3F, $FE00}
	// Critical first instructions.
	sei
	cld
	// Map bank 3 to 8000-9FFF for the rest of the reset code.
	lda.b #6
	sta.w $8000
	lsr
	sta.w $8001
	// Jump to the replacement.
	jmp reset_moved
	{warnpc $FE0E}

	// Some unused space ($500 bytes) in bank 3.
	{reorg $03, $8400}
	// Continuation of reset code.
reset_moved:
	// Copy original reset code's FE02-FE66 inclusive here.  This part is relocatable.
	incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10 + ($3F * $2000) + ($FE02 & $1FFF), $FE67 - $FE02

	// Don't do FE67-FE70 yet, because this changes the PRG-ROM banks and
	// would pull the rug out from under us.  Instead, delay it to the end.
	// This code is customized versus the original.

	// Set the CHR banks to CHR-RAM.  This code is like the original, except
	// that bit $40 is set to indicate to the different mapper to use CHR-RAM.
	ldx.b #(.chr_ram_banks_end - .chr_ram_banks) - 1
.chr_ram_set_loop:
	stx.w $8000
	lda.w .chr_ram_banks, x
	sta.w $8001
	dex
	bpl .chr_ram_set_loop

	// Clear OAM - same subroutine as other code we use.
	jsr $C421

	// Wipe the nametables.
	// NOTE: I think that this is a bug: the game put the MMC3 into horizontal
	// mirroring mode, so this overwrites the same location twice >.<
	lda.b #$20
	ldx.b #$00
	ldy.b #$00
	jsr .fill_vram
	lda.b #$24
	ldx.b #$00
	ldy.b #$00
	jsr .fill_vram

	// Create the main_loop ($C50C) coroutine as the bootstrap.
	lda.b #($C50C >> 8)
	sta.b $94
	lda.b #($C50C & $FF)
	sta.b $93
	lda.b #0
	jsr $FEED

	// main_loop and NMI write this to $2000.  main_loop's write will
	// therefore enable NMI.  The $08 bit sets the sprite CHR table to $1000.
	lda.b #%10001000
	sta.b {ram_zp_2000_shadow_2}

	// Map banks $3C and $3D to 8000-BFFF before the coroutine executes.
	// Because this bank switch will swap out the code we're executing now,
	// set up the routine to return to $FEA5, the coroutine loop of reset.
	lda.b #($FEA5 - 1) >> 8
	pha
	lda.b #($FEA5 - 1) & $FF
	pha
	ldx.b #$3C
	stx.b {ram_zp_request_8000_bank}
	inx
	stx.b {ram_zp_request_A000_bank}
	jmp {rom_prg_bank_switch}

.fill_vram:
	// Copy the relocatable routine at $C3D5 here to open up more space.
	incbin "Rockman 4 - Aratanaru Yabou!! (Japan).nes", $10 + ($3E * $2000) + ($C3D5 & $1FFF), $C421 - $C3D5

.chr_ram_banks:
	db $40, $42, $44, $45, $46, $47
.chr_ram_banks_end:


	// Delete the tail end of main_loop both so that we get control and so
	// that we can reuse its space.
	{savepc}
	{reorg $3E, $C7F6}
	lda.b #3
	sta.b {ram_zp_request_8000_bank}
	jsr {rom_prg_bank_switch}
	jmp end_level_hook

	// And here's what we replace it with.
	// Lookup table to convert a binary value to BCD.
bcd_table:
	incsrc "bcdtable50.asm"
	{warnpc $C846}
	{loadpc}

end_level_hook:
	// I don't know what this code does.
	lda.b {ram_zp_current_level}
	sta.w $0147
	lda.b #0
	sta.b $9A
	sta.w $06F0
	sta.w $06F1
	sta.w $06F2
	sta.w $06F3

	// Why did the level end?
	// Note that we ignore $13 (play ending) so ending never plays.
	lda.b {ram_zp_rockman_state}
	cmp.b #$07
	beq .death
	cmp.b #$11
	beq .got_balloon_or_wire

	// Exit the level.  Do some shenanigans here to set up the return addresses
	// when we can't JSR directly.
	lda.b #0
	sta.b $1F
	jsr $C846

	// After the bank switch, call 39:8003 then jump to C541.
	lda.b #($C541 - 1) >> 8
	pha
	lda.b #($C541 - 1) & $FF
	pha
	lda.b #($8003 - 1) >> 8
	pha
	lda.b #($8003 - 1) & $FF
	pha
	lda.b #$39
	sta.b {ram_zp_request_8000_bank}
	jmp {rom_prg_bank_switch}

.death:
.got_balloon_or_wire:
	// In both these cases, just reload the level at the midpoint.
	// This patch also has the side effect of infinite lives.
	lda.b #0
	sta.b $9A

	// More fun with the stack.
	lda.b #($C541 - 1) >> 8
	pha
	lda.b #($C541 - 1) & $FF
	pha
	lda.b #$39
	sta.b {ram_zp_request_8000_bank}
	jmp {rom_prg_bank_switch}

	{warnpc $8900}
{loadpc}


// Code that must go into banks 3E/3F.
{savepc}
	{reorg $3E, $C3D5}

	// NMI hook.  I copied the Rockman 3 practice ROM's hook code.
nmi_hook:
	// First deleted instruction.
	inc.b $92

	// Increment frame counter.
	inc.w {current_time_frames}
	lda.w {current_time_frames}
	cmp.b #60
	bne .no_carry
	inc.w {current_time_seconds}
	lda.b #0
	sta.w {current_time_frames}
.no_carry:

	// Second deleted instruction.
	ldx.b #$FF
	jmp $C0F1


	// Called during normal gameplay.
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
	lda.w {current_time_frames}
	sta.w {last_time_frames}
	ldx.w {current_time_seconds}
	stx.w {last_time_seconds}
	//cmp.w current_time_frames
	//bne .latch_loop
	jmp $C421


	{warnpc $C421}

	// Overwrites that jump into the above code.
	{reorg $3E, $C0ED}
	jmp nmi_hook
{loadpc}


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


// Main code to draw times during transition screens.
{savepc}
	{reorg $3F, $FE0E}
oam_hook_transition:
	// Normal mode - use original sprite table.
	lda.b #0
	sta.w {sprite_tile_select}

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
	sta.w {current_time_frames}
	sta.w {current_time_seconds}

	// Build the sprite records for the time display.
	// This is size-optimized rather than speed-optimized.
	ldx.b #16
.sprite_loop:
	lda.b #16
	sta.w $0204, x          // Y coordinate
	lda.b #%00000001
	sta.w $0206, x          // attributes and palette
	txa
	asl                     // add 8 each round
	adc.b #208
	sta.w $0207, x          // X coordinate
	dex
	dex
	dex
	dex
	bpl .sprite_loop

	// Tile IDs.
	// Apostrophe.
	lda.b #$4C
	sta.w $020D

	// This is supposed to point to the next available slot in the OAM buffer.
	lda.b #$18
	sta.b $97

	// Use the double-return trick to execute the below code twice.
	ldx.b #0
	ldy.w {last_time_seconds}
	jsr .repeat
	ldx.b #12
	ldy.w {last_time_frames}
.repeat:
	cpy.b #50
	bcs .fifty
	lda bcd_table, y
	bpl .not_fifty         // bcd_value has only $00-$49, so bpl always branches.
.fifty:
	lda bcd_table - 50, y
	adc.b #$50 - 1         // we know carry is set, because bcs branched here.
.not_fifty:
	pha
	and.b #$0F
	clc
	adc.w {sprite_tile_select}
	tay
	lda sprite_tile_table, y
	sta.w $0209, x
	pla
	lsr
	lsr
	lsr
	lsr
	clc
	adc.w {sprite_tile_select}
	tay
	lda sprite_tile_table, y
	sta.w $0205, x
	
	// Done.
	rts

// Mapping from numbers to sprite IDs.
sprite_tile_table:
	// Screen transition version:
	db $5A, $5B, $6A, $6B, $7E, $7F, $60, $61, $62, $63
	// Boss kill, death animation version:
	db $5A, $5B, $6A, $6B, $7E, $7F, $60, $61, $62, $63

	{warnpc $FEA5}
{loadpc}


// Immediately return to level select after a stage ends.
{savepc}
	{reorg $39, $8C6B}
	// Address of level select routine.
	jmp $8ECA

	// Because we just deleted a giant function, we can use the rest of its space.

	// Hook the code to load the stage select background.
show_screen_hook:
	// A contains the previous value of $10, which we check to determine whether
	// the screen being loaded is stage select.
	cmp.b #2
	bne .return
	lda.b $2A
	cmp.b #0
	bne .return
	beq .yes_stage_select
		
.return:
	// Return to caller.  Reload A, then multiply by 8 for the deleted code.
	lda.b $10
	asl
	asl
	asl
	rts

.yes_stage_select:
	// Force blanking here, and stop NMI from messing with us.
	jsr {rom_force_blank_on}

	// The previous MMC3 mirroring setting remains.  If the previous level was
	// vertically-oriented when the level exited, we need to reset the mirroring.
	lda.b #%00000001
	sta.w $A000

	// Save current A000 bank.
	lda.b {ram_zp_request_A000_bank}
	pha

	// Do the VRAM copies.
	ldx.b #0
.copy_outer_loop:
	lda.w .copy_table, x
	bmi .copy_done
	// First byte is bank to read from.  rom_prg_bank_switch saves X.
	sta.b {ram_zp_request_A000_bank}
	jsr {rom_prg_bank_switch}
	// Second byte is length.  $00 means $100.
	inx
	lda.w .copy_table, x
	inx
	sta.b $02
	// Third and fourth bytes are the VRAM address.
	// Note that 2006 takes the high byte first.
	lda.w $2002                 // reset address latch
	lda.w .copy_table + 1, x
	sta.w $2006
	lda.w .copy_table, x
	sta.w $2006
	inx
	inx
	// Fifth and sixth bytes are where to read from.
	lda.w .copy_table, x
	inx
	sta.b $00
	lda.w .copy_table, x
	inx
	sta.b $01
	// Copy data to VRAM.
	ldy.b #0
.copy_inner_loop:
	lda ($00), y
	sta.w $2007
	iny
	cpy.b $02
	bne .copy_inner_loop
	beq .copy_outer_loop

.copy_done:
	// While we're here, clear out the completed stages list.
	lda.b #$00
	sta.b {ram_zp_completed_stages}
	sta.b {ram_zp_completed_stages} + 1

	// Disable force blank and continue.
	jsr {rom_force_blank_off}

	// Restore original bank and return.
	pla
	sta.b {ram_zp_request_A000_bank}
	jsr {rom_prg_bank_switch}
	jmp .return

.copy_table:
	// Table of ROM addresses to copy to VRAM.
	// Add "COSSACK & WILY" text to robot master selection screen.
	db $27, tilemap_cossack_name.end - tilemap_cossack_name
	dw $222C, (tilemap_cossack_name & $1FFF) + $A000
	db $27, tilemap_andwily_name.end - tilemap_andwily_name
	dw $224C, (tilemap_andwily_name & $1FFF) + $A000
	// Ampersand for "COSSACK & WILY".
	db $27, tiles_ampersand.end - tiles_ampersand
	dw $0000 + ($FA * $10), (tiles_ampersand & $1FFF) + $A000
	// Copy tilemap_second_level_select to VRAM 2800.
	// This has the Cossack and Wily stage select.
	db $27, $100 & $FF
	dw $2800, ((tilemap_second_level_select + $000) & $1FFF) + $A000
	db $27, $100 & $FF
	dw $2900, ((tilemap_second_level_select + $100) & $1FFF) + $A000
	db $27, $100 & $FF
	dw $2A00, ((tilemap_second_level_select + $200) & $1FFF) + $A000
	db $27, $100 & $FF
	dw $2B00, ((tilemap_second_level_select + $300) & $1FFF) + $A000
	// Overwrite "CAPCOM" from "CAPCOM PRESENTS" with the Dr. Wily logo,
	// since we don't need that bitmap anymore for stage select.
	db $27, tiles_drwily_logo.end - tiles_drwily_logo
	dw $0000 + ($4A * $10), (tiles_drwily_logo & $1FFF) + $A000
	// End of table.
	db $FF


// Clear the timer when teleporting into a level.
// This actually gets mapped to the A000 bank because we call it from the
// 8000 bank.
teleport_in_hook:
	// Clear the timers.
	lda.b #0
	sta.w {current_time_seconds}
	sta.w {current_time_frames}
	// Deleted code (except the lda #0)
	sta.b {ram_zp_rockman_state}
	sta.b $A3
	sta.b $A7
	sta.b $A8
	lda.b #1
	sta.b $31
	sta.w $0420
	// Return to caller.
	sty.b {ram_zp_request_A000_bank}
	jmp {rom_prg_bank_switch}


	{warnpc $8ECA}
{loadpc}


// Hook the code to load the stage select background.
{savepc}
	{reorg $39, $84C9}
	jsr show_screen_hook
{loadpc}


// Hook teleporting into a level.
{savepc}
	{reorg $3C, $875E}
	// The target above is assembled as if in the 8000 bank,
	// but we're calling it in the A000 bank.
	// WARNING: THIS PATCH MUST BE EXACTLY 17 BYTES.
	lda.b {ram_zp_request_A000_bank}
	tay
	lda.b #$39
	sta.b {ram_zp_request_A000_bank}
	jsr {rom_prg_bank_switch}
	jsr teleport_in_hook + $2000
	nop
	nop
	nop
	nop
	{warnpc $876F}
{loadpc}


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
	lda.b {ram_zp_2000_shadow_1}
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
	lda.b {ram_zp_2000_shadow_1}
	eor.b #%00000010
	sta.b {ram_zp_2000_shadow_1}

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

	// Although it only matters for display, set lives and E-tanks to 9.
	lda.b #9
	sta.b {ram_zp_etanks}

	// Give the player the weapons that they should have on this stage.
	lda.w $1234
	lda.b {ram_zp_current_level}
	asl
	tax
	cpx.b #weapon_give_table.last - weapon_give_table
	bcc .weapon_not_cossack
	ldx.b #weapon_give_table.last - weapon_give_table
.weapon_not_cossack:
	lda.w weapon_give_table, x
	sta.b $00
	lda.w weapon_give_table + 1, x
	sta.b $01
	ldx.b #0
	ldy.b #8
.weapon_first_loop:
	lsr.b $00
	lda.b #$00
	bcc .weapon_first_nope
	lda.b #$9C
.weapon_first_nope:
	sta.b {ram_zp_energy}, x
	inx
	dey
	bne .weapon_first_loop
	ldy.b #6
.weapon_second_loop:
	lsr.b $01
	lda.b #$00
	bcc .weapon_second_nope
	lda.b #$9C
.weapon_second_nope:
	sta.b {ram_zp_energy}, x
	inx
	dey
	bne .weapon_second_loop

	// I don't know what these do, but the original code does it here.
	lda.b #0
	sta.b $2A
	sta.b $24
	rts

.cossack_wily_table:
	// Map from the 9 cursor position to levels.
	db 8, 9, 10, 11, $FF, 12, 13, 14, 15

// The Y positions of the sprites on the stage select screen.
// We use this to restore when flipping "pages".
level_select_sprite_y_table:
	incbin "sprite-y-positions.bin"
.end:

// Table of what weapons to give you on each stage.
weapon_give_table:
	//  DCBA9876543210
	// 2. Bright Man            (player gets Balloon during Pharaoh)
	dw %00100001000011
	// 8. Toad Man              (player gets Rush Jet for beating Drill Man)
	dw %11111111000111
	// 7. Drill Man
	dw %11110111000011
	// 1. Pharoah Man
	dw %00000000000011
	// 3. Ring Man
	dw %01100001000011
	// 4. Dust Man
	dw %01100101000011
	// 6. Dive Man
	dw %11110101000011
	// 5. Skull Man
	dw %01110101000011
.last:
	// 9-16. Cossack 1~Wily 4   (player gets Rush Marine for beating Toad Man)
	dw %11111111011111

	// We can overwrite all the way through the Cossack castle intro code.
	{warnpc $820A}
{loadpc}


{savepc}
// Handles pause screen choices.
// Overwrites code for showing Dr. Cossack's castle; useless for us.
// NOTE: This code executes from the A000 bank instead of 8000.
	{reorg $39, $A32C}
pause_screen_hook:
	// Deleted code we execute no matter what.
	lda.b #0
	sta.w $0131
	ldx.w $0138
	// We're called when the user has chosen.
	lda.b {ram_zp_controller1_new}
	and.b #$20
	beq .not_select
	// Trigger a stage exit.
	lda.b #$08
	bne .yes_select
.not_select:
	// Deleted code.
	cpx.b #$07
	beq .use_etank
	// The original code writes 00, so do that if not select.
	lda.b #$00
.yes_select:
	sta.b {ram_zp_rockman_state}
	// Return address.
	lda.b #($972C - 1) >> 8
	pha
	lda.b #($972C - 1) & $FF
	pha
	sty.b {ram_zp_request_A000_bank}
	jmp {rom_prg_bank_switch}
.use_etank:
	// Return address.
	lda.b #($96E8 - 1) >> 8
	pha
	lda.b #($96E8 - 1) & $FF
	pha
	sty.b {ram_zp_request_A000_bank}
	jmp {rom_prg_bank_switch}

	{warnpc $A3D8}
{loadpc}


// Bank $3C overwrites.
{savepc}
	// Infinite E-tanks.
	{reorg $3C, $96F2}
	nop
	nop
	// Add the select button to the buttons that can exit the pause screen.
	{reorg $3C, $96D9}
	and.b #$B0
	// Hook when leaving the pause screen.
	{reorg $3C, $9720}
	ldy.b {ram_zp_request_A000_bank}
	lda.b #$39
	sta.b {ram_zp_request_A000_bank}
	jsr {rom_prg_bank_switch}
	jmp pause_screen_hook
	{warnpc $972C}
	// Delete the write to ram_zp_rockman_state; we do our own above.
	{reorg $3C, $973C}
	nop
	nop
	// Hurry up E-tank refills.
	// Disabled this hack until I hear whether this would interfere with timing.
	//{reorg $3C, $9704}
	//ldx.b #2
{loadpc}


// Bank $27 overwrites.
{savepc}
	{reorg $27, $B800}

// Tilemap layout for when the player hits select.
tilemap_second_level_select:
	incbin "stageselect-nametable.bin"

// Bitmap data for the Dr. Wily logo.
tiles_drwily_logo:
	incbin "drwily-logo.bin"
.end:

// Bitmap data for an ampersand.
tiles_ampersand:
	db %11110111
	db %10001011
	db %01010111
	db %10101111
	db %11010101
	db %10101011
	db %01110110
	db %10001001

	db %10001111 & %11110111
	db %01110111 & %10001011
	db %10101111 & %01010111
	db %11011111 & %10101111
	db %10101011 & %11010101
	db %01110111 & %10101011
	db %10001001 & %01110110
	db %11111111 & %10001001
.end:

// Tilemap for "COSSACK".
tilemap_cossack_name:
	db $82, $8E, $92, $92, $80, $82, $8A
.end:

// Tilemap for " & WILY".
tilemap_andwily_name:
	db $10, $FA, $10, $96, $88, $8B, $98
.end:

	{warnpc $C000}
{savepc}
