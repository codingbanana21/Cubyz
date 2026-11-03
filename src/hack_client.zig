const std = @import("std");

const main = @import("main");

/// Client-side cheat state. Everything here runs on the main thread.
pub var flyEnabled: bool = false;
pub var ghostEnabled: bool = false;
pub var instantBreak: bool = false;
pub var radiusBreak: bool = false;
pub var breakRadius: i32 = 3;
pub var speedMultiplier: f32 = 1.0;
pub var jumpMultiplier: f64 = 1.0;

/// While instant break is on, block breaking progress per frame is multiplied by this.
pub const instantBreakFactor: f64 = 1000000;

pub const minRadius: i32 = 1;
pub const maxRadius: i32 = 8;
/// Limits how many blocks radius break sends to the server in a single frame.
pub const maxBlocksPerFrame: u32 = 200;

pub const minSpeed: f32 = 1;
pub const maxSpeed: f32 = 16;
pub const minJump: f64 = 1;
pub const maxJump: f64 = 16;

const menuId = "hack_menu";

/// Set while we are the ones keeping the player's flags on, so turning a hack off
/// doesn't cancel normal creative-mode flying or ghost mode.
var forcedFly: bool = false;
var forcedGhost: bool = false;

fn textInputActive() bool {
	return main.gui.selectedTextInput != null;
}

/// Bound to 'P'. Opens the menu (freeing the mouse) or closes it (grabbing the mouse again).
pub fn toggleMenu(_: main.Window.Key.Modifiers) void {
	if (main.game.world == null) return;
	if (textInputActive()) return;
	if (main.gui.isWindowOpen(menuId)) {
		main.gui.closeWindow(menuId);
		if (!main.Window.grabbed) main.gui.toggleGameMenu();
	} else {
		if (main.Window.grabbed) main.gui.toggleGameMenu();
		main.gui.openWindow(menuId);
	}
}

pub fn toggleFlyNow() void {
	flyEnabled = !flyEnabled;
}

pub fn toggleGhostNow() void {
	ghostEnabled = !ghostEnabled;
}

pub fn toggleInstantBreakNow() void {
	instantBreak = !instantBreak;
}

pub fn toggleRadiusBreakNow() void {
	radiusBreak = !radiusBreak;
}

pub fn speedUpNow() void {
	speedMultiplier = @min(maxSpeed, speedMultiplier*2);
}

pub fn speedDownNow() void {
	speedMultiplier = @max(minSpeed, speedMultiplier/2);
}

pub fn jumpUpNow() void {
	jumpMultiplier = @min(maxJump, jumpMultiplier*2);
}

pub fn jumpDownNow() void {
	jumpMultiplier = @max(minJump, jumpMultiplier/2);
}

/// Called every frame from game.update() before the movement code runs.
/// Despite the name it handles both fly and ghost mode.
pub fn applyFly() void {
	const player = &main.game.player;

	if (ghostEnabled) {
		player.isGhost.store(true, .monotonic);
		forcedGhost = true;
	} else if (forcedGhost) {
		forcedGhost = false;
		player.isGhost.store(false, .monotonic);
	}

	if (flyEnabled or ghostEnabled) {
		player.isFlying.store(true, .monotonic);
		forcedFly = true;
	} else if (forcedFly) {
		forcedFly = false;
		if (!player.isGhost.load(.monotonic)) {
			player.isFlying.store(false, .monotonic);
		}
	}
}
