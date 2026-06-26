package main

import "core:fmt"
import rl "vendor:raylib"

GRID_SIZE: int : 6

Wall_Side :: enum u8 {
	North,
	South,
	East,
	West,
}

Wall_Flags :: bit_set[Wall_Side;u8]

Space :: struct {
	walls:  Wall_Flags,
	hidden: bool,
}

Position :: struct {
	x: int,
	y: int,
}

Lair :: struct {
	grid: [GRID_SIZE][GRID_SIZE]Space,
}

init_lair :: proc(lair: ^Lair) {
	for y in 0 ..< GRID_SIZE {
		for x in 0 ..< GRID_SIZE {
			cell := &lair.grid[y][x]
			cell.hidden = true

			if y == 0 {cell.walls |= {Wall_Side.North}}
			if y == GRID_SIZE - 1 {cell.walls |= {Wall_Side.South}}
			if x == 0 {cell.walls |= {Wall_Side.West}}
			if x == GRID_SIZE - 1 {cell.walls |= {Wall_Side.East}}
		}

	}
}

is_out_of_bounds :: proc(pos: Position) -> bool {
	if pos.x > GRID_SIZE - 1 || pos.y > GRID_SIZE - 1 || pos.x < 0 || pos.y < 0 {
		return true
	}
	return false
}

place_wall :: proc(lair: ^Lair, pos: Position, side: Wall_Side) {
	if is_out_of_bounds(pos) {
		return
	}

	cell := &lair.grid[pos.y][pos.x]
	cell.walls |= {side}

	adjecent_pos := get_adjacent_cell(pos, side)
	if is_out_of_bounds(adjecent_pos) {
		return
	}

	adjecent_wall := get_adjacent_wall(side)
	cell = &lair.grid[adjecent_pos.y][adjecent_pos.x]
	cell.walls |= {adjecent_wall}
}

get_adjacent_cell :: proc(pos: Position, side: Wall_Side) -> Position {
	new_pos := pos

	switch side {
	case Wall_Side.North:
		new_pos.y -= 1
	case Wall_Side.South:
		new_pos.y += 1
	case Wall_Side.East:
		new_pos.x += 1
	case Wall_Side.West:
		new_pos.x -= 1
	}

	return new_pos
}

get_adjacent_wall :: proc(side: Wall_Side) -> Wall_Side {
	new_side: Wall_Side
	switch side {
	case Wall_Side.North:
		new_side = Wall_Side.South
	case Wall_Side.South:
		new_side = Wall_Side.North
	case Wall_Side.East:
		new_side = Wall_Side.West
	case Wall_Side.West:
		new_side = Wall_Side.East
	}

	return new_side
}

set_opposite_wall :: proc(lair: ^Lair, pos: Position, side: Wall_Side) {
	opposite_side: Wall_Side
	new_pos := pos


	if is_out_of_bounds(pos) {
		return
	}

	cell := &lair.grid[pos.y][pos.x]
	cell.walls |= {side}
}

main :: proc() {
	lair: Lair
	init_lair(&lair)

	place_wall(&lair, {x = 1, y = 1}, Wall_Side.East)
	place_wall(&lair, {x = 1, y = 1}, Wall_Side.South)
	place_wall(&lair, {x = 2, y = 1}, Wall_Side.South)

	// print_grid(&lair)

	screen_width :: 1000
	screen_height :: 800
	rl.InitWindow(screen_width, screen_height, "Title")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	rl.SetExitKey(.ESCAPE)

	cell_width := screen_width / GRID_SIZE
	cell_height := screen_height / GRID_SIZE

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(rl.WHITE)

		for i in 0 ..< GRID_SIZE {
			x: i32 = i32(i) * i32(cell_width)
			y: i32 = i32(i) * i32(cell_height)

			rl.DrawLine(x, 0, x, screen_height, rl.GRAY)
			rl.DrawLine(0, y, screen_width, y, rl.GRAY)
		}
	}
}

// --- VISUAL GRID PRINTING ---
print_grid :: proc(lair: ^Lair) {
	// Column headers
	fmt.print("      ")
	for x in 0 ..< GRID_SIZE {
		fmt.printf("  %d   ", x)
	}
	fmt.println("")

	for y in 0 ..< GRID_SIZE {
		// Top border
		fmt.printf("  %d    +", y)
		for x in 0 ..< GRID_SIZE {
			cell := lair.grid[y][x]
			if Wall_Side.North in cell.walls {
				fmt.print("=====+")
			} else {
				fmt.print(" . . +")
			}
		}
		fmt.println("")

		// Cells
		fmt.print("       ")
		for x in 0 ..< GRID_SIZE {
			cell := lair.grid[y][x]

			if Wall_Side.West in cell.walls {
				fmt.print("| ")
			} else {
				fmt.print(": ")
			}

			fmt.printf("%d,%d ", x, y)
		}

		// Right wall
		last_cell := lair.grid[y][GRID_SIZE - 1]
		if Wall_Side.East in last_cell.walls {
			fmt.println("|")
		} else {
			fmt.println(":")
		}
	}

	// Bottom border
	fmt.print("       +")
	for x in 0 ..< GRID_SIZE {
		cell := lair.grid[GRID_SIZE - 1][x]
		if Wall_Side.South in cell.walls {
			fmt.print("=====+")
		} else {
			fmt.print(" . . +")
		}
	}
	fmt.println("")
}
