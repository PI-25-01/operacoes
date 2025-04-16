const std = @import("std");
const rl = @import("raylib");

const WINDOW_WIDTH = 1080;
const WINDOW_HEIGHT = 720;

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
        }
        rl.closeWindow();
    }

    while (!rl.windowShouldClose()) {
        if (rl.isFileDropped()) {
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

                var image_sum_img = rl.imageCopy(image1_img);
                var img_sum_colors = try rl.loadImageColors(image_sum_img);

                sumImgColors(&img_sum_colors, img1_colors, img2_colors);
                image_sum_img.data = img_sum_colors.ptr;
                image_sum_img.format = .uncompressed_r8g8b8a8;

                rl.imageFormat(&image_sum_img, format);

                image_sum = try rl.loadTextureFromImage(image_sum_img);
            }
        }
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        if (image1) |_| {
            // Imagens originais
            rl.drawTexture(image1.?, 0, 0, .white);
            rl.drawTexture(image2.?, 0, image1.?.height + 64, .white);

            // Operadar aritmeticamente
            rl.drawText("Operações aritméticas", image1.?.width + 64, 4, 32, .black);
            rl.drawText("Soma:", image1.?.width + 64, 32 + 4, 22, .black);
            rl.drawTexture(image_sum.?, image1.?.width + 64, 64, .white);
            rl.drawText("Subtração:", image1.?.width + 64, image1.?.height + 64 + 32 + 4, 22, .black);
        }
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
