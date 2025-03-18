mod colours;

use bevy::prelude::*;
use itertools::Itertools;
use rand::prelude::*;

fn main() {
    App::new()
        .insert_resource(ClearColor(Srgba::hex("#1f2638").unwrap().into()))
        .add_plugins(
            DefaultPlugins
                .set(WindowPlugin {
                    primary_window: Some(Window {
                        title: "2048".to_string(),
                        ..default()
                    }),
                    ..default()
                })
                .set(AssetPlugin {
                    file_path: std::env::current_dir()
                        .unwrap()
                        .into_os_string()
                        .into_string()
                        .unwrap(),
                    processed_file_path: std::env::current_dir()
                        .unwrap()
                        .into_os_string()
                        .into_string()
                        .unwrap(),
                    ..default()
                }),
        )
        .init_resource::<FontSpec>()
        .add_systems(
            Startup,
            (setup, spawn_board, apply_deferred, spawn_tiles).chain(),
        )
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
    physical_size: f32,
}

impl Board {
    fn new(size: u8) -> Self {
        let physical_size = f32::from(size) * TILE_SIZE + f32::from(size + 1) * TILE_SPACER;

        Self {
            size,
            physical_size,
        }
    }

    fn cell_position_to_physical(&self, pos: u8) -> f32 {
        let offset = -self.physical_size / 2.0 + 0.5 * TILE_SIZE;

        offset + f32::from(pos) * TILE_SIZE + f32::from(pos + 1) * TILE_SPACER
    }

    fn size(&self) -> Vec2 {
        Vec2::new(self.physical_size, self.physical_size)
    }
}

fn spawn_board(mut commands: Commands) {
    let board = Board::new(4);

    commands
        .spawn(Sprite {
            color: colours::BOARD,
            custom_size: Some(board.size()),
            ..default()
        })
        .with_children(|builder| {
            for tile in (0..board.size).cartesian_product(0..board.size) {
                builder.spawn((
                    Sprite {
                        color: colours::TILE_PLACEHOLDER,
                        custom_size: Some(Vec2::new(TILE_SIZE, TILE_SIZE)),
                        ..default()
                    },
                    Transform::from_xyz(
                        board.cell_position_to_physical(tile.0),
                        board.cell_position_to_physical(tile.1),
                        1.0,
                    ),
                ));
            }
        })
        .insert(board);
}

#[derive(Component)]
struct Points {
    value: u32,
}

#[derive(Component)]
struct Position {
    x: u8,
    y: u8,
}

fn spawn_tiles(mut commands: Commands, query_board: Query<&Board>, font_spec: Res<FontSpec>) {
    let board = query_board.single();

    let mut rng = rand::rng();
    let starting_tiles: Vec<(u8, u8)> = (0..board.size)
        .cartesian_product(0..board.size)
        .choose_multiple(&mut rng, 2);

    dbg!(&starting_tiles);

    for (x, y) in starting_tiles.iter() {
        let pos = Position { x: *x, y: *y };
        commands
            .spawn((
                Sprite {
                    color: colours::TILE,
                    custom_size: Some(Vec2::new(TILE_SIZE, TILE_SIZE)),
                    ..default()
                },
                Transform::from_xyz(
                    board.cell_position_to_physical(pos.x),
                    board.cell_position_to_physical(pos.y),
                    2.0,
                ),
            ))
            .with_children(|child_builder| {
                child_builder.spawn((
                    Text2d::new("2"),
                    TextFont {
                        font: font_spec.family.clone(),
                        font_size: 38.0,
                        ..default()
                    },
                    TextColor(Color::BLACK),
                    TextLayout::new_with_justify(JustifyText::Center),
                    Transform::from_xyz(0.0, 0.0, 2.0),
                ));
            })
            .insert(Points { value: 2 })
            .insert(pos);
    }
}

#[derive(Component)]
struct TileText;

#[derive(Resource)]
struct FontSpec {
    family: Handle<Font>,
}

impl FromWorld for FontSpec {
    fn from_world(world: &mut World) -> Self {
        let asset_server = world.get_resource_mut::<AssetServer>().unwrap();

        Self {
            family: asset_server.load("fonts/FiraSans-Bold.otf"),
        }
    }
}
