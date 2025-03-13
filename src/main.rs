mod colours;

use bevy::prelude::*;
use itertools::Itertools;

fn main() {
    App::new()
        .insert_resource(ClearColor(Srgba::hex("#1f2638").unwrap().into()))
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "2048".to_string(),
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, (setup, spawn_board))
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d);
}

const TILE_SIZE: f32 = 40.0;
const TILE_SPACER: f32 = 10.0;

#[derive(Component)]
struct Board {
    size: u8,
}

fn spawn_board(mut commands: Commands) {
    let board = Board { size: 4 };
    let physical_board_size =
        f32::from(board.size) * TILE_SIZE + f32::from(board.size + 1) * TILE_SPACER;

    commands
        .spawn(Sprite {
            color: colours::BOARD,
            custom_size: Some(Vec2::new(physical_board_size, physical_board_size)),
            ..default()
        })
        .with_children(|builder| {
            let offset = -physical_board_size / 2.0 + 0.5 * TILE_SIZE;

            for tile in (0..board.size).cartesian_product(0..board.size) {
                builder.spawn((
                    Sprite {
                        color: colours::TILE_PLACEHOLDER,
                        custom_size: Some(Vec2::new(TILE_SIZE, TILE_SIZE)),
                        ..default()
                    },
                    Transform::from_xyz(
                        offset
                            + f32::from(tile.0) * TILE_SIZE
                            + f32::from(tile.0 + 1) * TILE_SPACER,
                        offset
                            + f32::from(tile.1) * TILE_SIZE
                            + f32::from(tile.1 + 1) * TILE_SPACER,
                        1.0,
                    ),
                ));
            }
        })
        .insert(board);
}
