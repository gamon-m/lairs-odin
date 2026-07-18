package main

import "core:fmt"
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
						lair.grid[cell_pos.y][cell_pos.x].hidden = false
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

handle_moving_input :: proc(
	lair: ^Lair,
	player: ^Player,
	position: Position,
	move_mode: Move_Type,
	active_move_mode: ^i32,
) {
	if is_out_of_bounds(position) {
		return
	}

	switch move_mode {
	case .Creep:
		if !can_afford(player, move_mode) {
			return
		}
		if handle_creep(lair, player, position, move_mode) {
			handle_cost(player, move_mode)
			active_move_mode^ = i32(Move_Type.Creep)
		}
	case .Hustle:
		if player.hustle_remaining == 0 {
			if !can_afford(player, move_mode) {
				return
			}
			if handle_creep(lair, player, position, move_mode) {
				handle_cost(player, move_mode)
				if lair.grid[position.y][position.x].type == .None {
					player.hustle_remaining = 2
				} else {
					active_move_mode^ = i32(Move_Type.Creep)
				}
			}
		} else {
			if handle_creep(lair, player, position, move_mode) {
				player.hustle_remaining -= 1
				if lair.grid[position.y][position.x].type != .None {
					player.hustle_remaining = 0
				}
				if player.hustle_remaining == 0 {
					active_move_mode^ = i32(Move_Type.Creep)
				}
			}
		}
	case .Backtrack:
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			cell := lair.grid[position.y][position.x]
			if cell.hidden {
				return
			}

			if !player.backtrack_active {
				if !can_afford(player, move_mode) {
					return
				}
				handle_cost(player, move_mode)
				player.backtrack_active = true
				move_player(lair, player, position)
			} else {
				move_player(lair, player, position)
			}

			if cell.type != .None {
				player.backtrack_active = false
				active_move_mode^ = i32(Move_Type.Creep)
			}
		}
	case .Peer:
		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			cell := &lair.grid[position.y][position.x]

			if player.peer_position == {-1, -1} {
				direction := get_direction_from_player(player, position)
				if !is_move_legal(lair, player.position, direction, move_mode) {
					return
				}
				if !can_afford(player, move_mode) {
					return
				}
				handle_cost(player, move_mode)
				player.peer_position = position
				cell.hidden = false
			} else {
				if position != player.peer_position {
					return
				}
				move_player(lair, player, position)
				clear_peer_position(player)
				active_move_mode^ = i32(Move_Type.Creep)
			}
		}
	}
}

handle_creep :: proc(
	lair: ^Lair,
	player: ^Player,
	position: Position,
	move_type: Move_Type,
) -> bool {
	direction := get_direction_from_player(player, position)

	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		if !is_move_legal(lair, player.position, direction, move_type) {
			return false
		}

		move_player(lair, player, position)
		return true
	}
	return false
}

