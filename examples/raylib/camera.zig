// https://gist.github.com/JeffM2501/000787070aef421a00c02ae4cf799ea1
// *******************************************************************************************
//
//    raylib [core] example - Basic window
//
//    Welcome to raylib!
//
//    To test examples, just press F6 and execute raylib_compile_execute script
//    Note that compiled executable is placed in the same folder as .c file
//
//    You can find all basic examples on C:\raylib\raylib\examples folder or
//    raylib official webpage: www.raylib.com
//
//    Enjoy using raylib. :)
//
//    This example has been created using raylib 1.0 (www.raylib.com)
//    raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
//
//    Copyright (c) 2014 Ramon Santamaria (@raysan5)
//
// *******************************************************************************************/

const raylib = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

//------------------------------------------------------------------------------------
// Custom Functions Definition
//------------------------------------------------------------------------------------
// Draw cube textured
// NOTE: Cube position is the center position
fn DrawCubeTexture(texture: raylib.Texture2D, position: raylib.Vector3, width: f32, height: f32, length: f32, color: raylib.Color) void {
    const x = position.x;
    const y = position.y;
    const z = position.z;

    // Set desired texture to be enabled while drawing following vertex data
    raylib.rlSetTexture(texture.id);

    // Vertex data transformation can be defined with the commented lines,
    // but in this example we calculate the transformed vertex data directly when calling rlVertex3f()
    //rlPushMatrix();
    // NOTE: Transformation is applied in inverse order (scale -> rotate -> translate)
    //rlTranslatef(2.0f, 0.0f, 0.0f);
    //rlRotatef(45, 0, 1, 0);
    //rlScalef(2.0f, 2.0f, 2.0f);

    raylib.rlBegin(raylib.RL_QUADS);
    raylib.rlColor4ub(color.r, color.g, color.b, color.a);
    // Front Face
    raylib.rlNormal3f(0.0, 0.0, 1.0); // Normal Pointing Towards Viewer
    raylib.rlTexCoord2f(0.0, 0.0);
    raylib.rlVertex3f(x - width / 2, y - height / 2, z + length / 2); // Bottom Left Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 0.0);
    raylib.rlVertex3f(x + width / 2, y - height / 2, z + length / 2); // Bottom Right Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 1.0);
    raylib.rlVertex3f(x + width / 2, y + height / 2, z + length / 2); // Top Right Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 1.0);
    raylib.rlVertex3f(x - width / 2, y + height / 2, z + length / 2); // Top Left Of The Texture and Quad
    // Back Face
    raylib.rlNormal3f(0.0, 0.0, -1.0); // Normal Pointing Away From Viewer
    raylib.rlTexCoord2f(1.0, 0.0);
    raylib.rlVertex3f(x - width / 2, y - height / 2, z - length / 2); // Bottom Right Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 1.0);
    raylib.rlVertex3f(x - width / 2, y + height / 2, z - length / 2); // Top Right Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 1.0);
    raylib.rlVertex3f(x + width / 2, y + height / 2, z - length / 2); // Top Left Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 0.0);
    raylib.rlVertex3f(x + width / 2, y - height / 2, z - length / 2); // Bottom Left Of The Texture and Quad
    // Top Face
    raylib.rlNormal3f(0.0, 1.0, 0.0); // Normal Pointing Up
    raylib.rlTexCoord2f(0.0, 1.0);
    raylib.rlVertex3f(x - width / 2, y + height / 2, z - length / 2); // Top Left Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 0.0);
    raylib.rlVertex3f(x - width / 2, y + height / 2, z + length / 2); // Bottom Left Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 0.0);
    raylib.rlVertex3f(x + width / 2, y + height / 2, z + length / 2); // Bottom Right Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 1.0);
    raylib.rlVertex3f(x + width / 2, y + height / 2, z - length / 2); // Top Right Of The Texture and Quad
    // Bottom Face
    raylib.rlNormal3f(0.0, -1.0, 0.0); // Normal Pointing Down
    raylib.rlTexCoord2f(1.0, 1.0);
    raylib.rlVertex3f(x - width / 2, y - height / 2, z - length / 2); // Top Right Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 1.0);
    raylib.rlVertex3f(x + width / 2, y - height / 2, z - length / 2); // Top Left Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 0.0);
    raylib.rlVertex3f(x + width / 2, y - height / 2, z + length / 2); // Bottom Left Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 0.0);
    raylib.rlVertex3f(x - width / 2, y - height / 2, z + length / 2); // Bottom Right Of The Texture and Quad
    // Right face
    raylib.rlNormal3f(1.0, 0.0, 0.0); // Normal Pointing Right
    raylib.rlTexCoord2f(1.0, 0.0);
    raylib.rlVertex3f(x + width / 2, y - height / 2, z - length / 2); // Bottom Right Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 1.0);
    raylib.rlVertex3f(x + width / 2, y + height / 2, z - length / 2); // Top Right Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 1.0);
    raylib.rlVertex3f(x + width / 2, y + height / 2, z + length / 2); // Top Left Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 0.0);
    raylib.rlVertex3f(x + width / 2, y - height / 2, z + length / 2); // Bottom Left Of The Texture and Quad
    // Left Face
    raylib.rlNormal3f(-1.0, 0.0, 0.0); // Normal Pointing Left
    raylib.rlTexCoord2f(0.0, 0.0);
    raylib.rlVertex3f(x - width / 2, y - height / 2, z - length / 2); // Bottom Left Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 0.0);
    raylib.rlVertex3f(x - width / 2, y - height / 2, z + length / 2); // Bottom Right Of The Texture and Quad
    raylib.rlTexCoord2f(1.0, 1.0);
    raylib.rlVertex3f(x - width / 2, y + height / 2, z + length / 2); // Top Right Of The Texture and Quad
    raylib.rlTexCoord2f(0.0, 1.0);
    raylib.rlVertex3f(x - width / 2, y + height / 2, z - length / 2); // Top Left Of The Texture and Quad
    raylib.rlEnd();
    //rlPopMatrix();

    raylib.rlSetTexture(0);
}

pub fn main() void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 800;

    raylib.InitWindow(screenWidth, screenHeight, "raylib [camera] example - third person orbit camera");
    defer raylib.CloseWindow(); // Close window and OpenGL context
    raylib.SetTargetFPS(60);
    //--------------------------------------------------------------------------------------

    const img = raylib.GenImageChecked(256, 256, 64, 64, raylib.LIGHTGRAY, raylib.WHITE);
    const tx = raylib.LoadTextureFromImage(img);

    // setup initial camera data
    var orbitCam = raylib.Camera3D{
        .fovy = 45,
        .target = raylib.Vector3{ .x = 1, .y = 0, .z = 0 },
        .position = raylib.Vector3{ .x = 0, .y = 0, .z = 5 },
        .up = raylib.Vector3{ .x = 0, .y = 1, .z = 0 },
        .projection = raylib.CAMERA_PERSPECTIVE,
    };

    var camDist: f32 = 5.0; // how far away from the target the camera is (radius)
    var rotAngle: f32 = 45; // the rotation angle around the target  (around Y)
    var tiltAngle: f32 = 45; // the tilt tangle of the camera (up/down)

    const rotSpeed = 0.25; // to scale the mouse input
    const moveSpeed = 3.0; // to scale the linear input

    var cursorPos = raylib.GetMousePosition(); // save off current position so we have a start point

    // Main game loop
    while (!raylib.WindowShouldClose()) // Detect window close button or ESC key
    {
        if (raylib.IsMouseButtonDown(1)) // only rotate on right click
        {
            const newPos = raylib.GetMousePosition();

            // update the angles from the delta
            rotAngle += (newPos.x - cursorPos.x) * rotSpeed;
            tiltAngle += (newPos.y - cursorPos.y) * rotSpeed;

            // clamp the tilt so we don't get gymbal lock
            if (tiltAngle > 89)
                tiltAngle = 89;
            if (tiltAngle < 1)
                tiltAngle = 1;
        }

        // always update the position so we don't get jumps
        cursorPos = raylib.GetMousePosition();

        // vector in rotation space to move
        var moveVec = raylib.Vector3{ .x = 0, .y = 0, .z = 0 };

        if (raylib.IsKeyDown(raylib.KEY_W))
            moveVec.z = -moveSpeed * raylib.GetFrameTime();
        if (raylib.IsKeyDown(raylib.KEY_S))
            moveVec.z = moveSpeed * raylib.GetFrameTime();

        if (raylib.IsKeyDown(raylib.KEY_A))
            moveVec.x = -moveSpeed * raylib.GetFrameTime();
        if (raylib.IsKeyDown(raylib.KEY_D))
            moveVec.x = moveSpeed * raylib.GetFrameTime();

        // update zoom
        camDist += raylib.GetMouseWheelMove();
        if (camDist < 1)
            camDist = 1;

        // vector we are going to transform to get the camera offset from the target point
        var camPos = raylib.Vector3{ .x = 0, .y = 0, .z = camDist };

        const tiltMat = raylib.MatrixRotateX(tiltAngle * raylib.GetFrameTime()); // a matrix for the tilt rotation
        const rotMat = raylib.MatrixRotateY(rotAngle * raylib.GetFrameTime()); // a matrix for the plane rotation
        const mat = raylib.MatrixMultiply(tiltMat, rotMat); // the combined transformation matrix for the camera position

        camPos = raylib.Vector3Transform(camPos, mat); // transform the camera position into a vector in world space
        moveVec = raylib.Vector3Transform(moveVec, rotMat); // transform the movement vector into world space, but ignore the tilt so it is in plane

        orbitCam.target = raylib.Vector3Add(orbitCam.target, moveVec); // move the target to the moved position
        //
        orbitCam.position = raylib.Vector3Add(orbitCam.target, camPos); // offset the camera position by the vector from the target position

        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.RAYWHITE);

        raylib.BeginMode3D(orbitCam);
        raylib.DrawPlane(
            raylib.Vector3{ .x = 0, .y = 0, .z = 0 },
            raylib.Vector2{ .x = 50, .y = 50 },
            raylib.BLUE,
        ); // simple world plane

        // grid of cubes to make a "world"
        const spacing: f32 = 3;
        const count: f32 = 5;
        var x: f32 = -count * spacing;
        while (x <= count * spacing) : (x += spacing) {
            var z = -count * spacing;
            while (z <= count * spacing) : (z += spacing) {
                DrawCubeTexture(
                    tx,
                    raylib.Vector3{ .x = x, .y = 0.5, .z = z },
                    1,
                    1,
                    1,
                    raylib.WHITE,
                );
            }
        }

        // target point
        raylib.DrawSphere(orbitCam.target, 0.25, raylib.RED);

        raylib.EndMode3D();

        // instructions
        raylib.DrawText("Right drag to rotate, Wheel to zoom, WASD to move", 100, 760, 20, raylib.GREEN);
        raylib.DrawFPS(0, 0);
        raylib.EndDrawing();
        //----------------------------------------------------------------------------------
    }
}
