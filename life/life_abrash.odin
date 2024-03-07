package life

import "core:fmt"
import "core:slice"
import rl "vendor:raylib"

import "../data"

/*

                Michael Abrash's algorithm (adapted)

        - can't do border swapping
        - skips empty space
        - copies the entire board every frame
        - it's potentially faster than the simple algorithm when most cells
          are dead, and slower when most cells are alive.

        cell bit layout:
             ------- --- ---------
            | . . . | 0 | 0 0 0 0 |
             ------- --- ---------
                      ^      ^
                      |     neighbor count
                 cell state

*/

@(private="file") _ALIVE :: int(1) << 4   // must cast literals to shift them
@(private="file") _DEAD  :: 0
@(private="file") _COUNT :: 0xf
@(private="file") _BOARD :: 1
@(private="file") _BUFF  :: 0

life_init_abrash :: proc() {
	print("initing ABRASH algorithm")
	life.cells = _create_cells()

	revive_cell      = la_revive_cell
	kill_cell        = la_kill_cell
	randomize_cells  = la_randomize_cells
	fill_grid        = la_fill_grid
	clear_grid       = la_clear_grid
	compute_gen      = la_compute_gen
	draw_grid        = la_draw_grid
}

@(private="file")
_inbounds :: proc(x, y:int) -> bool {
	using data
	return x >= 0 && x < GW && y >= 0 && y < GH
}

@(private="file")
_create_cells :: proc() -> [2][][]int {
	using data
	// TODO: Abrash's algorithm only needs one array of cells
	// and can't do border swapping
	s1 := make([][]int, GH)
	s2 := make([][]int, GH)
	for j:=0; j<GH; j+=1 {
		s1[j] = make([]int, GW)
		s2[j] = make([]int, GW)
	}

	cells := [2][][]int{s1, s2}

	return cells
}

life_destroy_abrash :: proc() {
	for j in 0 ..< data.GH {
		delete(life.cells[0][j])
		delete(life.cells[1][j])
	}
	delete(life.cells[0])
	delete(life.cells[1])
}

@(private="file")
_copy_board :: proc() {
	using data
	c := life.cells[_BOARD]
	p := life.cells[_BUFF]

	for j in 0..<GH {
		pj, cj := p[j], c[j]
		for i in 0..<GW {
			pj[i] = cj[i]
		}
	}
}


la_revive_cell :: proc(x, y:int) {
	if !_inbounds(x, y) do return

	cy := life.cells[_BOARD][y]
	if cy[x] & _ALIVE != 0 do return

	cy[x] |= _ALIVE
	_update_neighbors(x, y, 1)
}


la_kill_cell :: proc(x, y:int) {
	if !_inbounds(x, y) do return

	cy := life.cells[_BOARD][y]
	if cy[x] & _ALIVE == 0 do return

	cy[x] &= ~_ALIVE
	_update_neighbors(x, y, -1)
}


@(private="file") _update_neighbors :: proc(x, y, n:int) {
	using data
	l  := (x-1 >= 0   ?  x-1  :  GW-1 )
	r  := (x+1 <  GW  ?  x+1  :  0    )
	u  := (y-1 >= 0   ?  y-1  :  GH-1 )
	d  := (y+1 <  GH  ?  y+1  :  0    )
	cy := life.cells[_BOARD][y] // Y
	cu := life.cells[_BOARD][u] // up
	cd := life.cells[_BOARD][d] // down

	cu[l] = cu[l] + n
	cu[x] = cu[x] + n
	cu[r] = cu[r] + n
	cy[l] = cy[l] + n
	cy[r] = cy[r] + n
	cd[l] = cd[l] + n
	cd[x] = cd[x] + n
	cd[r] = cd[r] + n
}

@(private="file")
_update_all_neighbors :: proc() {
	using data
	c := life.cells[_BOARD]

	for j in 0..<GH {
		cj := c[j]
		for i in 0..<GW {
			if (cj[i] & _ALIVE) != 0 {
				_update_neighbors(i, j, 1)
			}
		}
	}
}

la_randomize_cells :: proc() {
	using data
	la_clear_grid()

	c := life.cells[_BOARD]

	for j in 0..<GH {
		for i in 0..<GW {
			alive := rl.GetRandomValue(0, 100) > 50
			c[j][i] = alive ? _ALIVE : _DEAD
		}
	}

	_update_all_neighbors()
}

la_fill_grid :: proc() {
	la_clear_grid(_ALIVE)
}

la_clear_grid :: proc(val:=_DEAD) {
	using data
	c := life.cells[_BOARD]

	for j in 0..<GH {
		for i in 0..<GW {
			c[j][i] = val
		}
	}

	if val == _ALIVE {
		_update_all_neighbors()
	}
}



// // 	/***************************************************

// // 				Compute Generation

// // 	*/

la_compute_gen :: proc() {
	using data
	_copy_board()
	c := life.cells[_BOARD]
	p := life.cells[_BUFF]

	for j in 0..<GH {
		pj, cj := p[j], c[j]
		for i in 0..<GW {
			if pj[i] == 0 do continue

			cell := pj[i]
			n := cell & _COUNT

			if bool(cell & _ALIVE) {
				if n != 2 && n != 3 {
					cj[i] &= ~_ALIVE
					_update_neighbors(i, j, -1)
				}
			} else if (n == 3) {
				cj[i] |= _ALIVE
				_update_neighbors(i, j, 1)
			}
		}
	}
}




// // 	/***************************************************

// // 				Rendering

// // 	*/

la_draw_grid :: proc() {
	using data
	c := life.cells[_BOARD]

	for j in 0..<GH {
		for i in 0..<GW {
			if bool(c[j][i] & _ALIVE) do set_pixel(i, j, alive_color)
		}
	}
}




