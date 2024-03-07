package life

import "core:fmt"
import "core:slice"
import rl "vendor:raylib"

import "../data"

/*

		Simplest life algorithm

			- iterates the entire array to apply rules
			- swaps borders to avoid checking bounds
			- alternates between two boards to avoid slow copying

*/

@(private="file") curr :int
@(private="file") prev :int
@(private="file") ALIVE :: 1
@(private="file") DEAD  :: 0

life_init_simple :: proc(/*life:^Life*/) {
	print("initing SIMPLE algorithm")
	curr = 1
	prev = 0

	life.debug_draw_borders = false
	life.cells = _create_cells()

	revive_cell      = ls_revive_cell
	kill_cell        = ls_kill_cell
	randomize_cells  = ls_randomize_cells
	fill_grid        = ls_fill_grid
	clear_grid       = ls_clear_grid
	compute_gen      = ls_compute_gen
	draw_grid        = ls_draw_grid
}

@(private="file")
_inbounds :: proc(x, y:int) -> bool {
	using data
	// keep in mind the 1 cell border all around
	return x > 0 && x < GW-1 && y > 0 && y < GH-1
}

life_destroy_simple :: proc() {
	for j in 0 ..< data.GH {
		delete(life.cells[0][j])
		delete(life.cells[1][j])
	}
	delete(life.cells[0])
	delete(life.cells[1])
}

@(private="file")
_create_cells :: proc() -> [2][][]int {
	using data
	s1 := make([][]int, GH)
	s2 := make([][]int, GH)
	for j in 0 ..<GH {
		s1[j] = make([]int, GW)
		s2[j] = make([]int, GW)
	}

	cells := [2][][]int{s1, s2}

	// understanding Tetralux's post about slices and memory:
	//   https://discord.com/channels/568138951836172421/568871298428698645/1144199020152111176

	if life.wrap_around {
		/*
			Since I use row-major order, the horizontal borders (top & bottom)
			only need to be swapped once here.
			So the arrays at 0 and GH are actually the same array, and so
			are 1 and GH-1.
		*/
		delete(cells[0][GH-1] )
		delete(cells[0][0]    )  // gotta get rid of these
		delete(cells[1][GH-1] )  // or there's a memory leak
		delete(cells[1][0]    )

		cells[0][GH-1] = cells[0][1]
		cells[0][0]    = cells[0][GH-2]

		cells[1][GH-1] = cells[1][1]
		cells[1][0]    = cells[1][GH-2]
	}

	return cells
}


/***************************************************
		Compute Generation
*/
ls_compute_gen :: proc() {
	using data

	curr, prev = prev, curr
	p := life.cells[prev]
	c := life.cells[curr]

	l, r, u, d:int
	n:int // alive neighbor count

	for j in 1..<GH-1 {
		u, d = j-1, j+1
		for i in 1..<GW-1 {
			l, r = i-1, i+1

			n = (		// seems parentesis are needed for this ?!
				p[u][l]
			  + p[u][i]
			  + p[u][r]
			  + p[j][l]
			  + p[j][r]
			  + p[d][l]
			  + p[d][i]
			  + p[d][r]
			)

			c[j][i] = (n==3 || (n==2 && p[j][i]==1)) ? ALIVE : DEAD
		}
	}

	if life.wrap_around do _swap_borders()
}




/***************************************************
		Rendering
*/
ls_draw_grid :: proc() {
	using data
	c := life.cells[curr]

	for j in 1..<GH-1 {
		cj := c[j]
		for i in 1..<GW-1 {
			if bool(cj[i]) do set_pixel(i, j, alive_color)
		}
	}

	// TODO: add a way to turn this off without leaving a blank border
	_draw_border_cells()
}


@(private="file")
_draw_border_cells :: proc() {
	using data
	c := life.cells[curr]

	for j in 0..<GH {
		cj := c[j]
		if bool(cj[0])    do set_pixel(0, j, rl.RED)
		if bool(cj[GW-1]) do set_pixel(GW-1, j, rl.RED)
	}

	for i in 0..<GW {
		if bool(c[0][i])    do set_pixel(i, 0, rl.RED)
		if bool(c[GH-1][i]) do set_pixel(i, GH-1, rl.RED)
	}
}



@(private="file")
_swap_borders :: proc() {
	using data
	c := life.cells[curr]

	for j in 0..<GH {
		cj := c[j]
		cj[ 0  ] = cj[GW-2]
		cj[GW-1] = cj[ 1  ]
	}

	// no need to swap horizontal borders when using slices
	// c[GH-1] = c[1]
	// c[0]    = c[GH-2]
}

ls_revive_cell :: proc(x, y:int) {
	using data
	if !_inbounds(x, y) do return

	cy := life.cells[curr][y]
	cy[x] = ALIVE

	// update vertical borders
	if x ==  1   do cy[GW-1] = ALIVE
	if x == GW-2 do cy[ 0  ] = ALIVE
}

ls_kill_cell :: proc(x, y:int) {
	using data
	if !_inbounds(x, y) do return

	cy := life.cells[curr][y]
	cy[x] = DEAD

	// update vertical borders
	if x ==  1   do cy[GW-1] = DEAD
	if x == GW-2 do cy[ 0  ] = DEAD
}

ls_randomize_cells :: proc() {
	using data
	c := life.cells[curr]

	ls_clear_grid(DEAD)

	for j in 1..<GH-1 {
		for i in 1..<GW-1 {
			alive := rl.GetRandomValue(0, 100) > 50
			c[j][i] = alive ? ALIVE : DEAD
		}
	}
}

ls_fill_grid :: proc() {
	ls_clear_grid(ALIVE)
}


ls_clear_grid :: proc(val:=DEAD) {
	using data
	c := life.cells[curr]

	for j in 1..<GH-1 {
		for i in 1..<GW-1 {
			c[j][i] = val
		}
	}
}

