// Third Parties
const std = @import("std");

// dross-zig
const Dross = @import("../dross_zig.zig");
usingnamespace Dross;
// -----------------------------------------------------------------------------

// -----------------------------------------
//      - Player -
// -----------------------------------------

///
pub const Player = struct {
    sprite: ?*Sprite = undefined,
    position: Vector3 = undefined,

    const Self = @This();

    /// Allocates and builds a player
    /// Comments: The caller will be the owner of the memory
    pub fn build(allocator: *std.mem.Allocator) !*Self {
        var new_player = try allocator.create(Player);
        new_player.position = Vector3.new(0.0, 1.0, 0.0);
        new_player.sprite = try buildSprite(allocator, "player_idle", "assets/sprites/s_player.png");
        return new_player;
    }

    /// Frees any allocated memory
    pub fn free(self: *Self, allocator: *std.mem.Allocator) void {
        self.sprite.?.free(allocator);
        allocator.destroy(self.sprite.?);
    }

    /// Update logic
    pub fn update(self: *Self, delta: f32) void {
        const speed: f32 = 8.0 * delta;
        const movement_smoothing = 0.6;
        const player_direction = self.sprite.?.getFlipH();
        const input_horizontal = Input.getKeyPressedValue(DrossKey.KeyD) - Input.getKeyPressedValue(DrossKey.KeyA);
        const input_vertical = Input.getKeyPressedValue(DrossKey.KeyW) - Input.getKeyPressedValue(DrossKey.KeyS);

        const target_position = self.position.add( //
            Vector3.new( //
            input_horizontal * speed, //
            input_vertical * speed, //
            0.0, //
        ));

        self.position = self.position.lerp(target_position, movement_smoothing);
        //self.position = target_position;

        if (input_horizontal > 0.0 and player_direction) {
            self.sprite.?.setFlipH(false);
        } else if (input_horizontal < 0.0 and !player_direction) {
            self.sprite.?.setFlipH(true);
        }
    }

    /// Rendering event
    pub fn render(self: *Self) void {
        Renderer.drawSprite(self.sprite.?, self.position);
    }
};