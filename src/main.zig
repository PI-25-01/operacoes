const std = @import("std");
const rl = @import("raylib");

const WINDOW_WIDTH = 1080;
const WINDOW_HEIGHT = 720;

var camera = rl.Camera2D{
    .offset = .{ .x = WINDOW_WIDTH / 2, .y = WINDOW_HEIGHT / 2 },
    .target = .{ .x = 0, .y = 0 },
    .rotation = 0,
    .zoom = 1,
};

var image1: ?rl.Texture = null;
var image2: ?rl.Texture = null;

var image_sum: ?rl.Texture = null;
var image_sub: ?rl.Texture = null;
var image_flip: ?rl.Texture = null;

pub fn main() !void {
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Operações aritméticas/geometricas");
    defer {
        if (image1) |_| {
            rl.unloadTexture(image1.?);
            rl.unloadTexture(image2.?);
            rl.unloadTexture(image_sum.?);
            rl.unloadTexture(image_sub.?);
        }
        rl.closeWindow();
    }

    while (!rl.windowShouldClose()) {
        if (rl.isFileDropped()) {
            if (image1) |_| {
                rl.unloadTexture(image1.?);
                rl.unloadTexture(image2.?);
                rl.unloadTexture(image_sum.?);
                rl.unloadTexture(image_sub.?);
            }
            const files = rl.loadDroppedFiles();
            defer rl.unloadDroppedFiles(files);
            if (files.count != 2) {
                std.debug.print("Err: Número de errado de arquivos", .{});
            } else {
                image1 = try rl.loadTexture(std.mem.span(files.paths[0]));
                image2 = try rl.loadTexture(std.mem.span(files.paths[1]));

                const image1_img = try rl.loadImageFromTexture(image1.?);
                const image2_img = try rl.loadImageFromTexture(image2.?);
                const img1_colors = try rl.loadImageColors(image1_img);
                defer rl.unloadImageColors(img1_colors);
                const img2_colors = try rl.loadImageColors(image2_img);
                defer rl.unloadImageColors(img2_colors);
                const format = image1.?.format;

                // Somar I1 + I2
                var image_sum_img = rl.imageCopy(image1_img);
                var img_sum_colors = try rl.loadImageColors(image_sum_img);

                sumImgColors(&img_sum_colors, img1_colors, img2_colors);
                image_sum_img.data = img_sum_colors.ptr;
                image_sum_img.format = .uncompressed_r8g8b8a8;

                rl.imageFormat(&image_sum_img, format);

                image_sum = try rl.loadTextureFromImage(image_sum_img);

                // Subtrair I1 - I2
                var img_sub = rl.imageCopy(image1_img);
                var img_sub_colors = try rl.loadImageColors(img_sub);

                subImgColors(&img_sub_colors, img1_colors, img2_colors);
                img_sub.data = img_sub_colors.ptr;
                img_sub.format = .uncompressed_r8g8b8a8;

                rl.imageFormat(&img_sub, format);

                image_sub = try rl.loadTextureFromImage(img_sub);

                // Inverter vertical e horizontalmente
                var img_flip = rl.imageCopy(image1_img);
                var img_flip_colors = try rl.loadImageColors(img_flip);

                flipImgColors(&img_flip_colors);
                img_flip.data = img_flip_colors.ptr;
                img_flip.format = .uncompressed_r8g8b8a8;

                rl.imageFormat(&img_flip, format);

                image_flip = try rl.loadTextureFromImage(img_flip);
            }
        }

        if (rl.isMouseButtonDown(.left)) {
            camera.target.x -= rl.getMouseDelta().x * rl.getFrameTime() * 3000.0 * (1 / camera.zoom);
            camera.target.y -= rl.getMouseDelta().y * rl.getFrameTime() * 3000.0 * (1 / camera.zoom);
        }

        camera.zoom += rl.getMouseWheelMove() / 10;

        rl.beginDrawing();
        rl.beginMode2D(camera);
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        if (image1) |_| {
            // Imagens originais
            rl.drawText("Imagens originais", 0, 4, 32, .black);
            rl.drawTexture(image1.?, 0, 64, .white);
            rl.drawTexture(image2.?, 0, image1.?.height + 128 + 4, .white);

            // Operações aritméticas
            rl.drawText("Operações aritméticas", image1.?.width + 64, 4, 32, .black);
            rl.drawText("Soma:", image1.?.width + 64, 32 + 4, 22, .black);
            rl.drawTexture(image_sum.?, image1.?.width + 64, 64, .white);
            rl.drawText("Subtração:", image1.?.width + 64, image1.?.height + 64 + 32 + 4, 22, .black);
            rl.drawTexture(image_sub.?, image1.?.width + 64, image1.?.height + 128 + 4, .white);

            // Operações geométricas
            rl.drawText("Operações geométricas", 2 * (image1.?.width + 64), 4, 32, .black);
            rl.drawText("Inverter vertical e horizontalmente:", 2 * (image1.?.width + 64), 32 + 4, 22, .black);
            rl.drawTexture(image_flip.?, 2 * (image1.?.width + 64), 64, .white);
        }
        rl.endMode2D();
    }
}

fn sumImgColors(rs_colors: *[]rl.Color, colors1: []rl.Color, colors2: []rl.Color) void {
    for (0..colors1.len) |i| {
        if (@as(u16, colors1[i].r) + @as(u16, colors2[i].r) > 255) {
            rs_colors.ptr[i].r = @intCast((@as(u16, colors1[i].r) + @as(u16, colors2[i].r)) / 2);
        } else {
            rs_colors.ptr[i].r = colors1[i].r + colors2[i].r;
        }

        if (@as(u16, colors1[i].g) + @as(u16, colors2[i].g) > 255) {
            rs_colors.ptr[i].g = @intCast((@as(u16, colors1[i].g) + @as(u16, colors2[i].g)) / 2);
        } else {
            rs_colors.ptr[i].g = colors1[i].g + colors2[i].g;
        }

        if (@as(u16, colors1[i].b) + @as(u16, colors2[i].b) > 255) {
            rs_colors.ptr[i].b = @intCast((@as(u16, colors1[i].b) + @as(u16, colors2[i].b)) / 2);
        } else {
            rs_colors.ptr[i].b = colors1[i].b + colors2[i].b;
        }

        if (@as(u16, colors1[i].a) + @as(u16, colors2[i].a) > 255) {
            rs_colors.ptr[i].a = @intCast((@as(u16, colors1[i].a) + @as(u16, colors2[i].a)) / 2);
        } else {
            rs_colors.ptr[i].a = colors1[i].a + colors2[i].a;
        }
    }
}

fn subImgColors(rs_colors: *[]rl.Color, colors1: []rl.Color, colors2: []rl.Color) void {
    var negativest: i32 = 255;
    for (0..colors1.len) |i| {
        const r_sub = @as(i32, colors1[i].r) - @as(i32, colors2[i].r);
        if (r_sub < negativest) {
            negativest = r_sub;
        }
        const g_sub = @as(i32, colors1[i].g) - @as(i32, colors2[i].g);
        if (g_sub < negativest) {
            negativest = g_sub;
        }
        const b_sub = @as(i32, colors1[i].b) - @as(i32, colors2[i].b);
        if (b_sub < negativest) {
            negativest = b_sub;
        }
        const a_sub = @as(i32, colors1[i].a) - @as(i32, colors2[i].a);
        if (a_sub < negativest) {
            negativest = a_sub;
        }
    }

    for (0..colors1.len) |i| {
        const r_sub = @as(i32, colors1[i].r) - @as(i32, colors2[i].r);
        const g_sub = @as(i32, colors1[i].g) - @as(i32, colors2[i].g);
        const b_sub = @as(i32, colors1[i].b) - @as(i32, colors2[i].b);
        const a_sub = @as(i32, colors1[i].a) - @as(i32, colors2[i].a);

        rs_colors.ptr[i].r = @intCast(@divTrunc((r_sub - negativest) * 255, (255 - negativest)));
        rs_colors.ptr[i].g = @intCast(@divTrunc((g_sub - negativest) * 255, (255 - negativest)));
        rs_colors.ptr[i].b = @intCast(@divTrunc((b_sub - negativest) * 255, (255 - negativest)));
        rs_colors.ptr[i].a = @intCast(@divTrunc((a_sub - negativest) * 255, (255 - negativest)));
    }
}

fn flipImgColors(rs_colors: *[]rl.Color) void {
    const half = rs_colors.*.len / 2;
    for (0..half) |i| {
        rs_colors.*.ptr[i].r = rs_colors.*.ptr[i].r ^ rs_colors.*.ptr[rs_colors.*.len - i].r;
        rs_colors.*.ptr[i].g = rs_colors.*.ptr[i].g ^ rs_colors.*.ptr[rs_colors.*.len - i].g;
        rs_colors.*.ptr[i].b = rs_colors.*.ptr[i].b ^ rs_colors.*.ptr[rs_colors.*.len - i].b;
        rs_colors.*.ptr[i].a = rs_colors.*.ptr[i].a ^ rs_colors.*.ptr[rs_colors.*.len - i].a;

        rs_colors.*.ptr[rs_colors.*.len - i].r = rs_colors.*.ptr[i].r ^ rs_colors.*.ptr[rs_colors.*.len - i].r;
        rs_colors.*.ptr[rs_colors.*.len - i].g = rs_colors.*.ptr[i].g ^ rs_colors.*.ptr[rs_colors.*.len - i].g;
        rs_colors.*.ptr[rs_colors.*.len - i].b = rs_colors.*.ptr[i].b ^ rs_colors.*.ptr[rs_colors.*.len - i].b;
        rs_colors.*.ptr[rs_colors.*.len - i].a = rs_colors.*.ptr[i].a ^ rs_colors.*.ptr[rs_colors.*.len - i].a;

        rs_colors.*.ptr[i].r = rs_colors.*.ptr[i].r ^ rs_colors.*.ptr[rs_colors.*.len - i].r;
        rs_colors.*.ptr[i].g = rs_colors.*.ptr[i].g ^ rs_colors.*.ptr[rs_colors.*.len - i].g;
        rs_colors.*.ptr[i].b = rs_colors.*.ptr[i].b ^ rs_colors.*.ptr[rs_colors.*.len - i].b;
        rs_colors.*.ptr[i].a = rs_colors.*.ptr[i].a ^ rs_colors.*.ptr[rs_colors.*.len - i].a;
    }
}
