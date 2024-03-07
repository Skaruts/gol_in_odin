package life

import "core:fmt"
// import "core:slice"
// import rl "vendor:raylib"

import "../data"

print := fmt.println

Algorithm :: enum {
	SIMPLE,
	ABRASH,
}


Life :: struct {
	wrap_around        : bool,

	// Life Simple stuff
	debug_draw_borders : bool,
	cells              : [2][][]int,

	// Life Abrash stuff
	COUNT              : int,
	board              : int,
	buff               : int,
}

life : Life

revive_cell     : proc(x, y:int)
kill_cell       : proc(x, y:int)
randomize_cells : proc()
fill_grid       : proc()
clear_grid      : proc(val:=0)
compute_gen     : proc()
draw_grid       : proc()


init :: proc(which: Algorithm) {
	life = {
		wrap_around = true,
	}

	switch which {
		case .SIMPLE:  life_init_simple()
		case .ABRASH:  life_init_abrash()
	}
}

destroy :: proc(which: Algorithm) {
	switch which {
		case .SIMPLE: life_destroy_simple()
		case .ABRASH: life_destroy_abrash()
	}
}
