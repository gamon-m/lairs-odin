package main

import "core:math"
import rl "vendor:raylib"

GRID_SIZE: int : 6
CELL_SIZE: f32 : 100
INSET: f32 : 10

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

has_wall :: proc(space: Space, side: Wall_Side) -> bool {
	return side in space.walls
}

main :: proc() {
	lair: Lair
	init_lair(&lair)

	place_wall(&lair, {x = 1, y = 1}, Wall_Side.East)
	place_wall(&lair, {x = 1, y = 1}, Wall_Side.South)
	place_wall(&lair, {x = 2, y = 1}, Wall_Side.South)


	screen_width :: 1280
	screen_height :: 720

	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(screen_width, screen_height, "Title")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	rl.SetExitKey(.ESCAPE)

	camera := rl.Camera2D{}
	camera.target = {CELL_SIZE * f32(GRID_SIZE) / 2, CELL_SIZE * f32(GRID_SIZE) / 2}
	camera.offset = rl.Vector2{f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0}
	camera.zoom = 1

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			scale_x := f32(rl.GetScreenWidth()) / f32(screen_width)
			scale_y := f32(rl.GetScreenHeight()) / f32(screen_height)
			scale: f32 = math.min(scale_x, scale_y)

			camera.zoom = scale
			camera.offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(rl.WHITE)
		rl.BeginMode2D(camera)
		draw_grid(&lair)
		rl.EndMode2D()
	}
}

draw_walls :: proc(cell: Space, x: f32, y: f32, size: f32) {
	if has_wall(cell, Wall_Side.North) {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x, y = y - INSET / 2, width = size, height = INSET / 2},
			rl.BLACK,
		)
	}
	if has_wall(cell, Wall_Side.South) {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x, y = y + size, width = size, height = INSET / 2},
			rl.BLACK,
		)
	}
	if has_wall(cell, Wall_Side.East) {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x + size, y = y, width = INSET / 2, height = size},
			rl.BLACK,
		)
	}
	if has_wall(cell, Wall_Side.West) {
		// rl.DrawLineEx(rl.Vector2{x, y}, rl.Vector2{x, y + size}, INSET, rl.BLACK)
		rl.DrawRectangleRec(
			rl.Rectangle{x = x - INSET / 2, y = y, width = INSET / 2, height = size},
			rl.BLACK,
		)
	}
}

draw_corners :: proc(cell: Space, x: int, y: int, size: f32) {
	cell_start_x := f32(x) * CELL_SIZE + INSET
	cell_start_y := f32(y) * CELL_SIZE + INSET
	px := f32(x) * CELL_SIZE + (INSET / 2)
	py := f32(y) * CELL_SIZE + (INSET / 2)

	if (y != 0) {
		if (x != 0) {
			// top left
			rl.DrawRectangleRec(
				rl.Rectangle{x = px, y = py, width = INSET / 2, height = INSET / 2},
				rl.BLACK,
			)
		}
		if (x != GRID_SIZE - 1) {
			// top right
			rl.DrawRectangleRec(
				rl.Rectangle {
					x = cell_start_x + size,
					y = py,
					width = INSET / 2,
					height = INSET / 2,
				},
				rl.BLACK,
			)
		}
	}
	if (y != GRID_SIZE - 1) {
		if (x != 0) {
			// bottom left
			rl.DrawRectangleRec(
				rl.Rectangle {
					x = px,
					y = cell_start_y + size,
					width = INSET / 2,
					height = INSET / 2,
				},
				rl.BLACK,
			)
		}
		if (x != GRID_SIZE - 1) {
			// bottom right
			rl.DrawRectangleRec(
				rl.Rectangle {
					x = cell_start_x + size,
					y = cell_start_y + size,
					width = INSET / 2,
					height = INSET / 2,
				},
				rl.BLACK,
			)
		}
	}
}

draw_border :: proc() {
	rl.DrawRectangleLinesEx(
		rl.Rectangle {
			x = 0,
			y = 0,
			height = CELL_SIZE * f32(GRID_SIZE) + INSET,
			width = CELL_SIZE * f32(GRID_SIZE) + INSET,
		},
		INSET,
		rl.BLACK,
	)
}

draw_grid :: proc(lair: ^Lair) {
	line_thickness: f32 : 3

	for y in 0 ..< GRID_SIZE {
		for x in 0 ..< GRID_SIZE {
			cell := lair.grid[y][x]

			pos_x: f32 = f32(x) * CELL_SIZE + INSET
			pos_y: f32 = f32(y) * CELL_SIZE + INSET
			size: f32 = f32(CELL_SIZE - INSET)

			rl.DrawRectangleLinesEx(
				rl.Rectangle{height = size, width = size, x = pos_x, y = pos_y},
				line_thickness,
				rl.BEIGE,
			)

			draw_walls(cell, pos_x, pos_y, size)
			draw_corners(cell, x, y, size)
			draw_border()
		}
	}
}

