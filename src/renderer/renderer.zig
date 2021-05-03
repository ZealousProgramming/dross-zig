const c = @import("../c_global.zig").c_imp;
const gl = @import("backend/backend_opengl.zig");
const std = @import("std");

/// An enum to keep track of which graphics api is
/// being used, so the renderer can be api agnostic.
pub const BackendApi = enum(u8) {
    OpenGl,
    Vulkan,
    Dx12,
    //Metal, // Will probably never happen as it is such a smaller portion
};

pub var api: BackendApi = BackendApi.OpenGl;

// -----------------------------------------
//      - Renderer -
// -----------------------------------------

/// The main renderer for the application.
/// Meant to be MOSTLY backend agnostic.
pub const Renderer = struct {
    gl_backend: ?*gl.OpenGlBackend = undefined,
    clear_r: f32 = 0.2,
    clear_g: f32 = 0.3,
    clear_b: f32 = 0.3,

    /// Resizes the viewport to the given size and position 
    /// Returns: void
    /// x: c_int - x position of the viewport
    /// y: c_int - y position of the viewport
    /// width: c_int - width of the viewport
    /// height: c_int - height of the viewport
    /// Comment: INTERNAL use only.
    pub fn resizeViewport(self: *Renderer, x: c_int, y: c_int, width: c_int, height: c_int) void {
        switch (api) {
            BackendApi.OpenGl => {
                gl.resizeViewport(x, y, width, height);
            },
            BackendApi.Dx12 => {},
            BackendApi.Vulkan => {},
        }
    }

    /// Handles the rendering process
    /// Returns: void
    /// Comment: INTERNAL use only.
    pub fn render(self: *Renderer) void {
        switch (api) {
            BackendApi.OpenGl => {
                self.gl_backend.?.render(self.clear_r, self.clear_g, self.clear_b);
            },
            BackendApi.Dx12 => {},
            BackendApi.Vulkan => {},
        }
    }

    /// Builds the graphics API
    /// Returns: anyerror!void
    /// allocator: *std.mem.Allocator - The main application allocator 
    /// Comment: INTERNAL use only.
    pub fn buildBackend(self: *Renderer, allocator: *std.mem.Allocator) anyerror!void {
        switch (api) {
            BackendApi.OpenGl => {
                self.gl_backend = try allocator.create(gl.OpenGlBackend);
                try gl.build(self.gl_backend.?);
            },
            BackendApi.Dx12 => {},
            BackendApi.Vulkan => {},
        }
    }

    /// Frees any allocated memory that the Renderer owns
    /// Returns: void
    /// allocator: *std.mem.Allocator - The allocator that generated the memory
    /// Comment: INTERNAL use only.
    pub fn free(self: *Renderer, allocator: *std.mem.Allocator) void {
        switch (api) {
            BackendApi.OpenGl => {
                allocator.destroy(self.gl_backend.?);
            },
            BackendApi.Dx12 => {},
            BackendApi.Vulkan => {},
        }
    }

    /// Window resize callback for GLFW
    /// Returns: void
    /// Comments: INTERNAL use only.
    pub fn resizeInternal(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
        var x_pos: c_int = 0;
        var y_pos: c_int = 0;

        c.glfwGetWindowPos(window, &x_pos, &y_pos);

        switch (api) {
            BackendApi.OpenGl => {
                c.glViewport(x_pos, y_pos, width, height);
            },
            BackendApi.Dx12 => {},
            BackendApi.Vulkan => {},
        }
    }
};

/// Allocates and builds the renderer
/// Returns: anyerror!*Renderer
/// allocator: *std.mem.Allocator - The main application allocator
/// Comment: INTERNAL use only.
pub fn build(allocator: *std.mem.Allocator) anyerror!*Renderer {
    var renderer: *Renderer = try allocator.create(Renderer);

    renderer.clear_r = 0.2;
    renderer.clear_g = 0.2;
    renderer.clear_b = 0.2;

    try renderer.buildBackend(allocator);

    return renderer;
}