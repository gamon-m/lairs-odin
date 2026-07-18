package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

game_state: Game_States = .Building

main :: proc() {
	lair: Lair
	init_lair(&lair)

	player: Player
	init_player(&player, {-1, -1})

	screen_width :: 1280
	screen_height :: 720

	place_mode := Placing_State.Walls
	active_place_mode := i32(place_mode)

	move_mode := Move_Type.Creep
	active_move_mode := i32(move_mode)

	test_board(&lair, &player)

	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(screen_width, screen_height, "Title")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	rl.SetExitKey(.ESCAPE)
	font := rl.LoadFont("fonts/PixelOperator.ttf")

	rl.GuiLoadStyle("styles/genesis.rgs")
	rl.GuiSetFont(font)

	dungeon_icons := rl.LoadTexture("assets/dungeon_icons.png")
	defer rl.UnloadTexture(dungeon_icons)

	camera := rl.Camera2D{}
	camera.target = {CELL_SIZE * f32(GRID_SIZE) / 2, CELL_SIZE * f32(GRID_SIZE) / 2}
	camera.offset = rl.Vector2{f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0}
	camera.zoom = 4

	mouse_pos: rl.Vector2
	world_pos: rl.Vector2

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			scale_x := f32(rl.GetScreenWidth()) / f32(screen_width)
			scale_y := f32(rl.GetScreenHeight()) / f32(screen_height)
			scale: f32 = math.min(scale_x, scale_y)

			camera.zoom = scale * 4
			camera.offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
		}

		mouse_pos = rl.GetMousePosition()
		world_pos = rl.GetScreenToWorld2D(mouse_pos, camera)
		hovered_pos := cell_position_at_mouse(world_pos)

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.WHITE)

		rl.BeginMode2D(camera)
		draw_grid(&lair, dungeon_icons)
		if game_state != .Building {
			draw_player(&player, dungeon_icons)
			if move_mode == .Peer && player.peer_position != {-1, -1} {
				draw_peer_target_highlight(&player, hovered_pos)
			} else {
				draw_legal_moves(&player, &lair, hovered_pos, move_mode)
			}
		}
		rl.EndMode2D()

		if game_state == .Building {
			draw_debug(&lair)
			handle_building_input(&lair, world_pos, &place_mode)

			active_place_mode = i32(place_mode)
			draw_place_modes_toggles(&active_place_mode)

			place_mode = Placing_State(active_place_mode)

			if can_finish_building(&lair) {
				if draw_finish_building_button() {
					game_state = .Playing
					player.position = lair.start_pos
				}
			}
		} else if game_state == .Playing {
			draw_collected_debug(&player)
			if player.hustle_remaining > 0 {
				draw_move_mode_locked(.Hustle)
				move_mode = .Hustle
			} else if player.backtrack_active {
				draw_move_mode_locked(.Backtrack)
				move_mode = .Backtrack
			} else if player.peer_position != {-1, -1} {
				draw_move_mode_locked(.Peer)
				move_mode = .Peer
			} else {
				draw_move_type_toggles(&active_move_mode)
				move_mode = Move_Type(active_move_mode)
			}
			draw_cube_inventory(player.cubes)

			handle_moving_input(&lair, &player, hovered_pos, move_mode)

			draw_turn_count(&player)
			if player.hustle_remaining > 0 {
				draw_hustle_count(&player)
			}
			if player.backtrack_active {
				if draw_stop_backtrack_button() {
					player.backtrack_active = false
				}
			}
			if player.peer_position != {-1, -1} {
				if draw_stop_peer_button() {
					clear_peer_position(&player)
				}
			}
			if draw_end_turn_button(&player) {
				player.turn += 1
				player.hustle_remaining = 0
				player.backtrack_active = false
				clear_peer_position(&player)
				conserve_cubes(&player)
				reset_cubes(&player)
			}

			if is_win(&lair, &player) {
				draw_win_screen()
			}
		}
	}
}

