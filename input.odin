package main

import rl "vendor:raylib"

handle_building_input :: proc(lair: ^Lair, world_pos: rl.Vector2, place_mode: ^Placing_State) {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		if place_mode^ == .Walls {
			if lair.placed_counts.Walls < WALL_LIMIT {
				new_cell, side := find_closest_cells(world_pos, 2.0)
				if new_cell.x != -1 || new_cell.y != -1 || side != nil {
					place_wall(lair, new_cell, side)
				}
			}
		} else {
			cell_pos := get_cell_at_pos(world_pos)
			if !is_out_of_bounds({x = cell_pos.x, y = cell_pos.y}) {
				cell := &lair.grid[cell_pos.y][cell_pos.x]
				cell_type := get_cell_type_from_place_state(place_mode^)

				if cell.type == .None && !type_at_limit(lair, cell_type) {
					cell.type = cell_type
					if cell_type == .Start {
						lair.start_pos = cell_pos
					} else if cell_type == .Finish {
						lair.finish_pos = cell_pos
					}
					add_type_count(lair, cell_type)
				}

			}
		}
	}
	if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
		if place_mode^ == .Walls {
			new_cell, side := find_closest_cells(world_pos, 2.0)
			if new_cell.x != -1 || new_cell.y != -1 || side != nil {
				remove_wall(lair, new_cell, side)
			}
		} else {
			cell_pos := get_cell_at_pos(world_pos)
			if !is_out_of_bounds({x = cell_pos.x, y = cell_pos.y}) {
				cell := &lair.grid[cell_pos.y][cell_pos.x]
				cell_type := get_cell_type_from_place_state(place_mode^)
				if cell.type == cell_type {
					cell.type = .None
					if cell_type == .Start {
						lair.start_pos = {
							x = -1,
							y = -1,
						}
					}
					subtract_type_count(lair, cell_type)
				}
			}
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ONE) {
		place_mode^ = .Walls
	} else if rl.IsKeyPressed(rl.KeyboardKey.TWO) {
		place_mode^ = .Start
	} else if rl.IsKeyPressed(rl.KeyboardKey.THREE) {
		place_mode^ = .Finish
	} else if rl.IsKeyPressed(rl.KeyboardKey.FOUR) {
		place_mode^ = .Treasure
	} else if rl.IsKeyPressed(rl.KeyboardKey.FIVE) {
		place_mode^ = .Monster
	} else if rl.IsKeyPressed(rl.KeyboardKey.SIX) {
		place_mode^ = .Trap
	}

}

get_move_direction :: proc() -> rl.Vector2 {
	if rl.IsKeyPressed(rl.KeyboardKey.W) || rl.IsKeyPressed(rl.KeyboardKey.UP) {
		return {0, -1}
	} else if rl.IsKeyPressed(rl.KeyboardKey.S) || rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		return {0, 1}
	} else if rl.IsKeyPressed(rl.KeyboardKey.D) || rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
		return {1, 0}
	} else if rl.IsKeyPressed(rl.KeyboardKey.A) || rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
		return {-1, 0}
	} else {
		return {0, 0}
	}
}

