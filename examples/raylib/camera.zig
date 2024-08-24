// https://github.com/raysan5/raylib/blob/master/examples/models/models_geometric_shapes.c
//******************************************************************************************
//
//  raylib [models] example - Draw some basic geometric shapes (cube, sphere, cylinder...)
//
//  Example originally created with raylib 1.0, last time updated with raylib 3.5
//
//  Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
//  BSD-like license that allows static linking with closed source software
//
//  Copyright (c) 2014-2024 Ramon Santamaria (@raysan5)
//
//******************************************************************************************/
const std = @import("std");
const rowmath = @import("rowmath");
const c = @cImport({
    @cInclude("raylib.h");
});

fn to_raylib(src: rowmath.Vec3) c.Vector3 {
    return .{
        .x = src.x,
        .y = src.y,
        .z = src.z,
    };
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------

    c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE | c.FLAG_WINDOW_HIGHDPI);
    c.InitWindow(800, 450, "raylib [models] example - geometric shapes");
    defer c.CloseWindow(); // Close window and OpenGL context

    // Define the camera to look into our 3d world
    var camera = c.Camera{};
    var rowmath_camera = rowmath.Camera{};
    camera.fovy = std.math.radiansToDegrees(rowmath_camera.yFov);
    camera.projection = c.CAMERA_PERSPECTIVE;
    var right_drag = rowmath.makeYawPitchHandler(.right, &rowmath_camera);
    var middle_drag = rowmath.makeScreenMoveHandler(.middle, &rowmath_camera);

    c.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!c.WindowShouldClose()) // Detect window close button or ESC key
    {
        const screenWidth = c.GetScreenWidth();
        const screenHeight = c.GetScreenHeight();

        // update projection
        rowmath_camera.resize(.{
            .x = @floatFromInt(screenWidth),
            .y = @floatFromInt(screenHeight),
        });

        // update transform
        const input = rowmath.InputState{
            .screen_width = @floatFromInt(screenWidth),
            .screen_height = @floatFromInt(screenHeight),
            .mouse_x = @floatFromInt(c.GetMouseX()),
            .mouse_y = @floatFromInt(c.GetMouseY()),
            .mouse_left = c.IsMouseButtonDown(c.MOUSE_BUTTON_LEFT),
            .mouse_middle = c.IsMouseButtonDown(c.MOUSE_BUTTON_MIDDLE),
            .mouse_right = c.IsMouseButtonDown(c.MOUSE_BUTTON_RIGHT),
            .mouse_wheel = c.GetMouseWheelMove(),
        };
        right_drag.frame(input);
        middle_drag.frame(input);
        rowmath_camera.dolly(input.mouse_wheel);
        rowmath_camera.updateTransform();

        camera.up = to_raylib(rowmath_camera.transform.rotation.dirY());
        camera.position = to_raylib(rowmath_camera.transform.translation);
        camera.target = to_raylib(rowmath_camera.target());

        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.RAYWHITE);

        c.BeginMode3D(camera);
        defer c.EndMode3D();

        c.DrawCube(.{ .x = -4.0, .y = 0.0, .z = 2.0 }, 2.0, 5.0, 2.0, c.RED);
        c.DrawCubeWires(.{ .x = -4.0, .y = 0.0, .z = 2.0 }, 2.0, 5.0, 2.0, c.GOLD);
        c.DrawCubeWires(.{ .x = -4.0, .y = 0.0, .z = -2.0 }, 3.0, 6.0, 2.0, c.MAROON);

        c.DrawSphere(.{ .x = -1.0, .y = 0.0, .z = -2.0 }, 1.0, c.GREEN);
        c.DrawSphereWires(.{ .x = 1.0, .y = 0.0, .z = 2.0 }, 2.0, 16, 16, c.LIME);

        c.DrawCylinder(.{ .x = 4.0, .y = 0.0, .z = -2.0 }, 1.0, 2.0, 3.0, 4, c.SKYBLUE);
        c.DrawCylinderWires(.{ .x = 4.0, .y = 0.0, .z = -2.0 }, 1.0, 2.0, 3.0, 4, c.DARKBLUE);
        c.DrawCylinderWires(.{ .x = 4.5, .y = -1.0, .z = 2.0 }, 1.0, 1.0, 2.0, 6, c.BROWN);

        c.DrawCylinder(.{ .x = 1.0, .y = 0.0, .z = -4.0 }, 0.0, 1.5, 3.0, 8, c.GOLD);
        c.DrawCylinderWires(.{ .x = 1.0, .y = 0.0, .z = -4.0 }, 0.0, 1.5, 3.0, 8, c.PINK);

        c.DrawCapsule(.{ .x = -3.0, .y = 1.5, .z = -4.0 }, .{ .x = -4.0, .y = -1.0, .z = -4.0 }, 1.2, 8, 8, c.VIOLET);
        c.DrawCapsuleWires(.{ .x = -3.0, .y = 1.5, .z = -4.0 }, .{ .x = -4.0, .y = -1.0, .z = -4.0 }, 1.2, 8, 8, c.PURPLE);

        c.DrawGrid(10, 1.0); // Draw a grid

        c.DrawFPS(10, 10);
    }
}
