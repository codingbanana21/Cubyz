const std = @import("std");

const main = @import("main");
const Vec2f = main.vec.Vec2f;
const NeverFailingAllocator = main.heap.NeverFailingAllocator;

const gui = @import("../gui.zig");
const GuiComponent = gui.GuiComponent;
const GuiWindow = gui.GuiWindow;
const Label = GuiComponent.Label;
const Button = @import("../components/Button.zig");
const ContinuousSlider = @import("../components/ContinuousSlider.zig");
const VerticalList = @import("../components/VerticalList.zig");

const hack = main.hack_client;

pub var window: GuiWindow = GuiWindow{
	.relativePosition = .{
		.{.attachedToFrame = .{.selfAttachmentPoint = .upper, .otherAttachmentPoint = .upper}},
		.{.attachedToFrame = .{.selfAttachmentPoint = .upper, .otherAttachmentPoint = .upper}},
	},
	.contentSize = Vec2f{256, 128},
	.closeIfMouseIsGrabbed = true,
};

const padding: f32 = 8;

var shownFly: bool = false;
var shownGhost: bool = false;
var shownBreak: bool = false;
var shownRadiusBreak: bool = false;

fn addLine(list: anytype, comptime fmt: []const u8, args: anytype) void {
	var buf: [128]u8 = undefined;
	const text = std.fmt.bufPrint(&buf, fmt, args) catch "?";
	list.add(Label.init(.{0, 0}, 240, text, .left));
}

fn addButton(list: anytype, comptime fmt: []const u8, args: anytype, action: main.callbacks.SimpleCallback) void {
	var buf: [128]u8 = undefined;
	const text = std.fmt.bufPrint(&buf, fmt, args) catch "?";
	list.add(Button.initText(.{0, 0}, 240, text, .{.onAction = action}));
}

// The button callbacks only change state. refresh() runs from update() on the next frame,
// so a button is never destroyed while its own callback is running.
fn onFly() void {
	hack.toggleFlyNow();
}
fn onGhost() void {
	hack.toggleGhostNow();
}
fn onBreak() void {
	hack.toggleInstantBreakNow();
}
fn onRadiusBreak() void {
	hack.toggleRadiusBreakNow();
}

// The sliders update their own label while dragged, so they don't need a refresh.
fn setSpeed(value: f32) void {
	hack.speedMultiplier = value;
}
fn formatSpeed(allocator: NeverFailingAllocator, value: f32) []const u8 {
	return allocator.print("Speed: x{d:.1}", .{value});
}
fn setRadius(value: f32) void {
	hack.breakRadius = @intFromFloat(@round(value));
}
fn formatRadius(allocator: NeverFailingAllocator, value: f32) []const u8 {
	return allocator.print("Break radius: {d}", .{@as(i32, @intFromFloat(@round(value)))});
}
fn setJump(value: f32) void {
	hack.jumpMultiplier = value;
}
fn formatJump(allocator: NeverFailingAllocator, value: f32) []const u8 {
	return allocator.print("Jump height: x{d:.1}", .{value});
}

fn refresh() void {
	if (window.rootComponent) |old| {
		old.deinit();
		window.rootComponent = null;
	}
	shownFly = hack.flyEnabled;
	shownGhost = hack.ghostEnabled;
	shownBreak = hack.instantBreak;
	shownRadiusBreak = hack.radiusBreak;

	const list = VerticalList.init(.{padding, 16 + padding}, 300, 0);
	addButton(list, "Fly: {s}", .{if (hack.flyEnabled) "ON" else "OFF"}, .init(onFly));
	addButton(list, "Ghost: {s}", .{if (hack.ghostEnabled) "ON" else "OFF"}, .init(onGhost));
	addButton(list, "Instant break: {s}", .{if (hack.instantBreak) "ON" else "OFF"}, .init(onBreak));
	addButton(list, "Radius break: {s}", .{if (hack.radiusBreak) "ON" else "OFF"}, .init(onRadiusBreak));
	list.add(ContinuousSlider.init(.{0, 0}, 240, @floatFromInt(hack.minRadius), @floatFromInt(hack.maxRadius), @floatFromInt(hack.breakRadius), &setRadius, &formatRadius));
	list.add(ContinuousSlider.init(.{0, 0}, 240, hack.minSpeed, hack.maxSpeed, hack.speedMultiplier, &setSpeed, &formatSpeed));
	list.add(ContinuousSlider.init(.{0, 0}, 240, @floatCast(hack.minJump), @floatCast(hack.maxJump), @floatCast(hack.jumpMultiplier), &setJump, &formatJump));
	addLine(list, "Press P to close", .{});
	list.finish(.center);
	window.rootComponent = list.toComponent();
	window.contentSize = window.rootComponent.?.pos() + window.rootComponent.?.size() + @as(Vec2f, @splat(padding));
	window.contentSize[0] = @max(window.contentSize[0], window.getMinWindowWidth());
	gui.updateWindowPositions();
}

pub fn onOpen() void {
	refresh();
}

pub fn onClose() void {
	if (window.rootComponent) |root| {
		root.deinit();
		window.rootComponent = null;
	}
}

pub fn update() void {
	if (hack.flyEnabled != shownFly or hack.ghostEnabled != shownGhost or hack.instantBreak != shownBreak or hack.radiusBreak != shownRadiusBreak) {
		refresh();
	}
}
