// Third Parties
const c = @import("../../c_global.zig").c_imp;
const std = @import("std");
const za = @import("zalgebra");

// dross-zig
const VertexArrayGl = @import("vertex_array_opengl.zig").VertexArrayGl;
const vbgl = @import("vertex_buffer_opengl.zig");
const VertexBufferGl = vbgl.VertexBufferGl;
const BufferUsageGl = vbgl.BufferUsageGl;
const IndexBufferGl = @import("index_buffer_opengl.zig").IndexBufferGl;
const shad = @import("shader_opengl.zig");
const ShaderGl = shad.ShaderGl;
const ShaderTypeGl = shad.ShaderTypeGl;
const ShaderProgramGl = @import("shader_program_opengl.zig").ShaderProgramGl;
const Vertex = @import("../vertex.zig").Vertex;
// ----
const Color = @import("../../core/color.zig").Color;
const texture = @import("../texture.zig");
const TextureGl = @import("texture_opengl.zig").TextureGl;
const TextureId = texture.TextureId;
const TextureRegion = @import("../texture_region.zig").TextureRegion;
const Sprite = @import("../sprite.zig").Sprite;
const gly = @import("../font/glyph.zig");
const Glyph = gly.Glyph;
const font = @import("../font/font.zig");
const Font = font.Font;
const PackingMode = @import("../renderer.zig").PackingMode;
const ByteAlignment = @import("../renderer.zig").ByteAlignment;
const Camera = @import("../cameras/camera_2d.zig");
const Math = @import("../../math/math.zig").Math;
const Matrix4 = @import("../../core/matrix4.zig").Matrix4;
const Vector4 = @import("../../core/vector4.zig").Vector4;
const Vector3 = @import("../../core/vector3.zig").Vector3;
const Vector2 = @import("../../core/vector2.zig").Vector2;
const fs = @import("../../utils/file_loader.zig");
const rh = @import("../../core/resource_handler.zig");
const app = @import("../../core/application.zig");
const Application = @import("../../core/application.zig").Application;
const framebuffa = @import("../framebuffer.zig");
const Framebuffer = framebuffa.Framebuffer;
const FrameStatistics = @import("../../utils/profiling/frame_statistics.zig").FrameStatistics;
// ----------------------------------------------------------------------------------------

// Testing vertices and indices
// zig fmt: off
const square_vertices: [20]f32 = [20]f32{
    // Positions  / Texture coords
    // 1.0, 1.0, 0.0,  1.0, 1.0, // Top Right
    // 1.0, 0.0, 0.0,  1.0, 0.0,// Bottom Right
    // 0.0, 0.0, 0.0,  0.0, 0.0,// Bottom Left
    // 0.0, 1.0, 0.0,  0.0, 1.0,// Top Left

    0.0, 0.0, 0.0,  0.0, 0.0, // Bottom Left
    1.0, 0.0, 0.0,  1.0, 0.0,// Bottom Right
    1.0, 1.0, 0.0,  1.0, 1.0,// Top Right
    0.0, 1.0, 0.0,  0.0, 1.0,// Top Left
};

//[0  3]
//[2  1]
const square_indices: [6]c_uint = [6]c_uint{
    // 0, 1, 3,
    // 1, 2, 3,
    0, 1, 2,
    2, 3, 0
};

const screenbuffer_indices: [6]c_uint = [6]c_uint{
    0, 1, 2,
    0, 2, 3,
};

// zig fmt: off
//const screenbuffer_vertices: [24]f32 = [24]f32{
//    // Positions  / Texture coords
//    -1.0,  1.0,     0.0, 1.0, // Bottom Left
//    -1.0, -1.0,     0.0, 0.0,// Bottom Right
//     1.0, -1.0,     1.0, 0.0,// Top Right
//
//    -1.0,  1.0,     0.0, 1.0,// Top Left
//     1.0, -1.0,     1.0, 0.0,// Top Left
//     1.0,  1.0,     1.0, 1.0,// Top Left
//};

// zig fmt: off
const QUAD_TEXTURE_UV: [4]Vector2 = [4]Vector2 {
    Vector2.new(0.0, 0.0), // BL
    Vector2.new(1.0, 0.0), // BR
    Vector2.new(1.0, 1.0), // TR
    Vector2.new(0.0, 1.0), // TL
};

// zig fmt: off
const QUAD_VERTEX_POSITIONS: [4]Vector3 = [4]Vector3 {
    Vector3.new(0.0, 0.0, 0.0), // BL
    Vector3.new(1.0, 0.0, 0.0), // BR
    Vector3.new(1.0, 1.0, 0.0), // TR
    Vector3.new(0.0, 1.0, 0.0), // TL
};

// -----------------------------------------
//      - OpenGL Reference Material -
// -----------------------------------------
// OpenGL Types: https://www.khronos.org/opengl/wiki/OpenGL_Type
// Beginners:    https://learnopengl.com/Introduction

// -----------------------------------------
//      - GLSL Default Shaders -
// -----------------------------------------
const default_shader_vs: [:0]const u8 = "assets/shaders/default_shader.vs";
const default_shader_fs: [:0]const u8 = "assets/shaders/default_shader.fs";
const screenbuffer_shader_vs: [:0]const u8 = "assets/shaders/screenbuffer_shader.vs";
const screenbuffer_shader_fs: [:0]const u8 = "assets/shaders/screenbuffer_shader.fs";
const font_shader_vs: [:0]const u8 = "assets/shaders/font_shader.vs";
const font_shader_fs: [:0]const u8 = "assets/shaders/font_shader.fs";
const gui_shader_vs: [:0]const u8 = "assets/shaders/gui_shader.vs";
const gui_shader_fs: [:0]const u8 = "assets/shaders/gui_shader.fs";


// -----------------------------------------
//      - OpenGL Errors -
// -----------------------------------------
/// Error set for OpenGL related errors 
pub const OpenGlError = error{
    /// Glad failed to initialize
    GladFailure,
    /// Failure during shader compilation
    ShaderCompilationFailure,
    /// Failure during shader program linking
    ShaderLinkingFailure,
};

// -----------------------------------------
//      - GlPackingMode -
// -----------------------------------------

/// Describes what Packing Mode will be affected
/// by the following operations.
pub const GlPackingMode = enum(c_uint) {
    /// Affects the packing of pixel data 
    Pack = c.GL_PACK_ALIGNMENT,
    /// Affects the unpacking of pixel data
    Unpack = c.GL_UNPACK_ALIGNMENT,
};

// -----------------------------------------
//      - Renderer Maximums -
// -----------------------------------------
/// Maximum amount of quads per draw call
const MAX_QUADS = 10000;
/// Maximum amount of vertices used per draw call
const MAX_VERTICES = MAX_QUADS * 4;
/// Maximum amount of indices used per draw call
const MAX_INDICES = MAX_QUADS * 6;
/// Maximum amount of texture that can be bound per
/// draw call
const MAX_TEXTURE_SLOTS = 32;

// -----------------------------------------
//      - RendererGl -
// -----------------------------------------

/// Backend Implmentation for OpenGL
/// Comments: This is for INTERNAL use only. 
pub const RendererGl = struct {
    /// Default shader program for drawing the scene
    shader_program: ?*ShaderProgramGl = undefined,
    /// Shader program for drawing the swapchain to the display
    screenbuffer_program: ?*ShaderProgramGl = undefined,
    /// Font Rendering program for drawing text
    font_renderer_program: ?*ShaderProgramGl = undefined,
    /// GUI program for drawing on the GUI layer for non-font rendering draws
    gui_renderer_program: ?*ShaderProgramGl = undefined,

    current_program: *ShaderProgramGl = undefined,
    current_vertex_array: *VertexArrayGl = undefined,
    current_vertex_buffer: *VertexBufferGl = undefined,

    vertex_array: ?*VertexArrayGl = undefined,
    vertex_buffer: ?*VertexBufferGl = undefined,
    index_buffer: ?*IndexBufferGl = undefined,

    screenbuffer_vertex_array: ?*VertexArrayGl = undefined,
    screenbuffer_vertex_buffer: ?*VertexBufferGl = undefined,
    screenbuffer_index_buffer: ?*IndexBufferGl = undefined,

    font_renderer_vertex_array: ?*VertexArrayGl = undefined,
    font_renderer_vertex_buffer: ?*VertexBufferGl = undefined,
    font_renderer_index_buffer: ?*IndexBufferGl = undefined,

    gui_renderer_vertex_array: ?*VertexArrayGl = undefined,
    gui_renderer_vertex_buffer: ?*VertexBufferGl = undefined,
    gui_renderer_index_buffer: ?*IndexBufferGl = undefined,


    clear_color: Color = undefined,
    default_draw_color: Color = undefined,

    default_texture: ?*texture.Texture = undefined,

    screenbuffer: ?*Framebuffer = undefined,

    projection_view: ?Matrix4 = undefined,

    //quad_vertices: std.ArrayList(Vertex) = undefined,
    quad_vertex_base: []Vertex = undefined,
    quad_vertex_ptr: [*]Vertex = undefined,

    index_count: u32 = 0,
    vertex_count: u32 = 0,

    //texture_slots: std.ArrayHashMap(c_uint, void) = undefined,
    texture_slots: []c_uint = undefined,
    texture_slot_index: u32 = 1,

    screenbuffer_vertices: std.ArrayList(Vertex) = undefined,


    const Self = @This();

    /// Builds the necessary components for the OpenGL renderer
    /// Comments: INTERNAL use only. The OpenGlBackend will be the owner of the allocated memory.
    pub fn new(allocator: std.mem.Allocator) !*Self {
        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) return OpenGlError.GladFailure;

        var self = try allocator.create(RendererGl);

        // Set up the default quad vertices
        //self.quad_vertices = std.ArrayList(Vertex).init(allocator);
        // TODO(devon): Change to ensureTotalCapacity when Zig is upgraded to master.
        //try self.quad_vertices.ensureCapacity(MAX_VERTICES * @sizeOf(Vertex));
        self.quad_vertex_base = try allocator.alloc(Vertex, MAX_VERTICES);
        self.quad_vertex_ptr = self.quad_vertex_base.ptr;

        self.index_count = 0;
        
        //self.texture_slots = std.ArrayHashMap(c_uint, void).init(allocator);
        //self.texture_slots.ensureCapacity(MAX_TEXTURE_SLOTS);
        self.texture_slots = try allocator.alloc(c_uint, MAX_TEXTURE_SLOTS);
        self.texture_slot_index = 1;

        // -------------------
        
        // Set up the screenbuffer vertices
        self.screenbuffer_vertices = std.ArrayList(Vertex).init(allocator);
        // Top Left
        try self.screenbuffer_vertices.append(Vertex{
            .x = 1.0, .y = 1.0, .z = 0.0, 
            .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0,
            .u = 1.0, .v = 1.0,
            .index = 0.0,
        });
        // Bottom Left 
        try self.screenbuffer_vertices.append(Vertex{
            .x = -1.0, .y = 1.0, .z = 0.0, 
            .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0,
            .u = 0.0, .v = 1.0,
            .index = 0.0,
        });
        // Bottom Right
        try self.screenbuffer_vertices.append(Vertex{
            .x = -1.0, .y = -1.0, .z = 0.0, 
            .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0,
            .u = 0.0, .v = 0.0,
            .index = 0.0,
        });
        // Top Right
        try self.screenbuffer_vertices.append(Vertex{
            .x = 1.0, .y = -1.0, .z = 0.0, 
            .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0,
            .u = 1.0, .v = 0.0,
            .index = 0.0,
        });

        // -------------------



        // Sets the pixel storage mode that affefcts the operation
        // of subsequent glReadPixel as well as unpacking texture patterns.
        //c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
        self.setByteAlignment(PackingMode.Unpack, ByteAlignment.One);
        
        // Enable depth testing
        c.glEnable(c.GL_DEPTH_TEST);
        c.glEnable(c.GL_BLEND);
        c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

        // Vertex Shaders
        // -------------------------------------------

        // Allocate and compile the vertex shader
        var vertex_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Vertex);
        try vertex_shader.source(default_shader_vs);
        try vertex_shader.compile();

        // Allocate and compile the vertex shader for the screenbuffer
        var screenbuffer_vertex_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Vertex);
        try screenbuffer_vertex_shader.source(screenbuffer_shader_vs);
        try screenbuffer_vertex_shader.compile();

        // Allocate and compile the vertex shader for the font rendering
        var font_renderer_vertex_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Vertex);
        try font_renderer_vertex_shader.source(font_shader_vs);
        try font_renderer_vertex_shader.compile();
        
        // Allocate and compile the vertex shader for the font rendering
        var gui_renderer_vertex_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Vertex);
        try gui_renderer_vertex_shader.source(gui_shader_vs);
        try gui_renderer_vertex_shader.compile();
        

        // Fragment Shaders
        // -------------------------------------------

        // Allocate and compile the fragment shader
        var fragment_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Fragment);
        try fragment_shader.source(default_shader_fs);
        try fragment_shader.compile();

        // Allocate and compile the vertex shader for the screenbuffer
        var screenbuffer_fragment_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Fragment);
        try screenbuffer_fragment_shader.source(screenbuffer_shader_fs);
        try screenbuffer_fragment_shader.compile();
        
        // Allocate and compile the fragment shader for the font rendering
        var font_renderer_fragment_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Fragment);
        try font_renderer_fragment_shader.source(font_shader_fs);
        try font_renderer_fragment_shader.compile();
        
        // Allocate and compile the fragment shader for the font rendering
        var gui_renderer_fragment_shader: *ShaderGl = try ShaderGl.new(allocator, ShaderTypeGl.Fragment);
        try gui_renderer_fragment_shader.source(gui_shader_fs);
        try gui_renderer_fragment_shader.compile();



        // Default shader program setup
        // ---------------------------------------------------

        // Allocate memory for the shader program
        self.shader_program = try ShaderProgramGl.new(allocator);

        // Attach the shaders to the shader program
        self.shader_program.?.attach(vertex_shader);
        self.shader_program.?.attach(fragment_shader);

        // Link the shader program
        try self.shader_program.?.link();

        // Free the memory as they are no longer needed
        ShaderGl.free(allocator, vertex_shader);
        ShaderGl.free(allocator, fragment_shader);

        // Screenbuffer shader program setup
        // ----------------------------------------------------

        // Allocate memory for the shader program
        self.screenbuffer_program = try ShaderProgramGl.new(allocator);

        // Attach the shaders to the shader program
        self.screenbuffer_program.?.attach(screenbuffer_vertex_shader);
        self.screenbuffer_program.?.attach(screenbuffer_fragment_shader);

        // Link the shader program
        try self.screenbuffer_program.?.link();

        // Free the memory as they are no longer needed
        ShaderGl.free(allocator, screenbuffer_vertex_shader);
        ShaderGl.free(allocator, screenbuffer_fragment_shader);


        // Font Renderer shader program setup
        // ----------------------------------------------------

        // Allocate memory for the shader program
        self.font_renderer_program = try ShaderProgramGl.new(allocator);

        // Attach the shaders to the shader program
        self.font_renderer_program.?.attach(font_renderer_vertex_shader);
        self.font_renderer_program.?.attach(font_renderer_fragment_shader);

        // Link the shader program
        try self.font_renderer_program.?.link();

        // Free the memory as they are no longer needed
        ShaderGl.free(allocator, font_renderer_vertex_shader);
        ShaderGl.free(allocator, font_renderer_fragment_shader);
        
        // GUI Renderer shader program setup
        // ----------------------------------------------------

        // Allocate memory for the shader program
        self.gui_renderer_program = try ShaderProgramGl.new(allocator);

        // Attach the shaders to the shader program
        self.gui_renderer_program.?.attach(gui_renderer_vertex_shader);
        self.gui_renderer_program.?.attach(gui_renderer_fragment_shader);

        // Link the shader program
        try self.gui_renderer_program.?.link();
        
        // Free the memory as they are no longer needed
        ShaderGl.free(allocator, gui_renderer_vertex_shader);
        ShaderGl.free(allocator, gui_renderer_fragment_shader);

        // Create VAO, VBO, and IB
        // -----------------------------------------------------
        self.vertex_array = try VertexArrayGl.new(allocator);
        self.vertex_buffer = try VertexBufferGl.new(allocator);
        self.index_buffer = try IndexBufferGl.new(allocator);
        // --
        self.screenbuffer_vertex_array = try VertexArrayGl.new(allocator);
        self.screenbuffer_vertex_buffer = try VertexBufferGl.new(allocator);
        self.screenbuffer_index_buffer = try IndexBufferGl.new(allocator);
        // --
        self.font_renderer_vertex_array = try VertexArrayGl.new(allocator);
        self.font_renderer_vertex_buffer = try VertexBufferGl.new(allocator);
        self.font_renderer_index_buffer = try IndexBufferGl.new(allocator);
        // --
        self.gui_renderer_vertex_array = try VertexArrayGl.new(allocator);
        self.gui_renderer_vertex_buffer = try VertexBufferGl.new(allocator);
        self.gui_renderer_index_buffer = try IndexBufferGl.new(allocator);

        // Default VAO/VBO/IB
        // -----------------------------------------------------------

        // Bind VAO
        // NOTE(devon): Order matters! Bind VAO first, and unbind last!
        self.vertex_array.?.bind();

        // Bind VBO
        self.vertex_buffer.?.bind();
        //var vertices_slice = square_vertices[0..];
        //var vertices_slice = self.quad_vertices.items[0..];
        //var vertices_slice = self.quad_vertex_base[0..];
        //self.vertex_buffer.?.data(vertices_slice, BufferUsageGl.StaticDraw);
        //self.vertex_buffer.?.dataV(vertices_slice, BufferUsageGl.DynamicDraw);
        self.vertex_buffer.?.dataV(self.quad_vertex_base, BufferUsageGl.DynamicDraw);
        

        // Fill the indices
        // This will be deleted once we get out of scope.
        var quad_indices_ar: [MAX_INDICES]c_uint = undefined;
        var indicies_index: usize = 0;
        var index_offset: c_uint = 0;
        while(indicies_index < MAX_INDICES) : (indicies_index += 6) {
            quad_indices_ar[indicies_index + 0] = index_offset + 0;
            quad_indices_ar[indicies_index + 1] = index_offset + 1;
            quad_indices_ar[indicies_index + 2] = index_offset + 2;
            quad_indices_ar[indicies_index + 3] = index_offset + 2;
            quad_indices_ar[indicies_index + 4] = index_offset + 3;
            quad_indices_ar[indicies_index + 5] = index_offset + 0;

            index_offset += 4;
        }

        // Bind IB
        self.index_buffer.?.bind();
        var indicies_slice = quad_indices_ar[0..];
        self.index_buffer.?.data(indicies_slice, BufferUsageGl.StaticDraw);

        //const size_of_vatb = 5;
        const size_f32 = @sizeOf(f32);
        const stride = @intCast(c_longlong, @sizeOf(Vertex));
        //const stride = @intCast(c_longlong, @sizeOf(f32) * size_of_vatb);
        const offset_position: u32 = 0;
        const offset_color: u32 = 3 * size_f32;
        const offset_tex: u32 =  7 * size_f32; // position offset(0)  + the length of the color bytes
        const offset_index: u32 = 9 * size_f32;
        //const offset_tex: u32 =  3 * @sizeOf(f32); // position offset(0)  + the length of the color bytes
        const index_zero: c_int = 0;
        const index_one: c_int = 1;
        const index_two: c_int = 2;
        const index_three: c_int = 3;
        const size_position: c_uint = 3;
        const size_color: c_uint = 4;
        const size_tex_coords: c_uint = 2;
        const size_index: c_uint = 1;

        // Tells OpenGL how to interpret the vertex data(per vertex attribute)
        // Uses the data to the currently bound VBO

        // Position Attribute
        c.glVertexAttribPointer(
            index_zero, // Which vertex attribute we want to configure
            size_position, // Size of vertex attribute (vec3 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            stride, // Stride
            @intToPtr(?*anyopaque, offset_position), // Offset
        );

        // Vertex Attributes are disabled by default, we need to enable them.
        c.glEnableVertexAttribArray(index_zero);

        // Color Attribute
        c.glVertexAttribPointer(
            index_one, // Which vertex attribute we want to configure
            size_color, // Size of vertex attribute (vec2 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            stride, // Stride
            @intToPtr(?*anyopaque, offset_color), // Offset
        );

        // Enable Texture Coordinate Attribute
        c.glEnableVertexAttribArray(index_one);


        // Texture Coordinates Attribute
        c.glVertexAttribPointer(
            index_two, // Which vertex attribute we want to configure
            size_tex_coords, // Size of vertex attribute (vec2 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            stride, // Stride
            @intToPtr(?*anyopaque, offset_tex), // Offset
        );

        // Enable Texture Coordinate Attribute
        c.glEnableVertexAttribArray(index_two);
            
        // Texture Index Attribute
        c.glVertexAttribPointer(
            index_three, // Which vertex attribute we want to configure
            size_index, // Size of vertex attribute (vec2 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            stride, // Stride
            @intToPtr(?*anyopaque, offset_index), // Offset
        );

        // Enable Texture Coordinate Attribute
        c.glEnableVertexAttribArray(index_three);

        // Unbind the VBO
        c.glBindBuffer(c.GL_ARRAY_BUFFER, index_zero);

        // NOTE(devon): Do NOT unbind the EBO while a VAO is active as the bound
        // bound element buffer object IS stored in the VAO; keep the EBO bound.
        // Unbind the EBO

        // Setup screenbuffer VAO/VBO
        // ---------------------------------------------------
        self.screenbuffer_vertex_array.?.bind();
        self.screenbuffer_vertex_buffer.?.bind();
        var screenbuffer_vertices_slice = self.screenbuffer_vertices.items[0..];
        //var screenbuffer_vertices_slice = screenbuffer_vertices[0..];
        self.screenbuffer_vertex_buffer.?.dataV(screenbuffer_vertices_slice, BufferUsageGl.StaticDraw);
        //self.screenbuffer_vertex_buffer.?.data(screenbuffer_vertices_slice, BufferUsageGl.StaticDraw);
        // Bind IB
        self.screenbuffer_index_buffer.?.bind();
        var buffer_slice = screenbuffer_indices[0..];
        self.screenbuffer_index_buffer.?.data(buffer_slice, BufferUsageGl.StaticDraw);


        //const screenbuffer_stride = @intCast(c_longlong, @sizeOf(f32) * 4);
        //const screenbuffer_offset_tex: u32 =  2 * @sizeOf(f32); // position offset(0)  + the length of the color bytes
        const screenbuffer_stride = @intCast(c_longlong, @sizeOf(Vertex));
        const screenbuffer_offset_color: u32 = 3 * size_f32;
        const screenbuffer_offset_tex: u32 =  7 * size_f32; // position offset(0)  + the length of the color bytes
        //const screenbuffer_offset_index: u32 = 9 * size_f32;

        c.glEnableVertexAttribArray(index_zero);

        c.glVertexAttribPointer(
            index_zero, 
            size_position,
            c.GL_FLOAT,
            c.GL_FALSE,
            screenbuffer_stride,
            @intToPtr(?*anyopaque, offset_position), // Offset
        );

        c.glEnableVertexAttribArray(index_one);

        c.glVertexAttribPointer(
            index_one, 
            size_color,
            c.GL_FLOAT,
            c.GL_FALSE,
            screenbuffer_stride,
            @intToPtr(?*anyopaque, screenbuffer_offset_color), // Offset
        );

        c.glEnableVertexAttribArray(index_two);

        c.glVertexAttribPointer(
            index_two, 
            size_tex_coords,
            c.GL_FLOAT,
            c.GL_FALSE,
            screenbuffer_stride,
            @intToPtr(?*anyopaque, screenbuffer_offset_tex), // Offset
        );

        //c.glEnableVertexAttribArray(index_three);

        //c.glVertexAttribPointer(
        //    index_three, 
        //    size_index,
        //    c.GL_FLOAT,
        //    c.GL_FALSE,
        //    screenbuffer_stride,
        //    @intToPtr(?*anyopaque, screenbuffer_offset_index), // Offset
        //);

        // Setup framebuffers
        // const screen_buffer_size = Vector2.new(1280, 720);
        const screen_buffer_size = Application.viewportSize();
        self.screenbuffer = try Framebuffer.new(allocator);
        self.screenbuffer.?.bind(framebuffa.FramebufferType.Read);
        self.screenbuffer.?.addColorAttachment(
            allocator, 
            framebuffa.FramebufferAttachmentType.Color0, 
            screen_buffer_size,
        );
        self.screenbuffer.?.check();

        framebuffa.Framebuffer.resetFramebuffer();


        // Font Renderer
        // ------------------------------------------
        self.font_renderer_vertex_array.?.bind();
        self.font_renderer_vertex_buffer.?.bind();
        self.vertex_buffer.?.dataV(self.quad_vertex_base, BufferUsageGl.DynamicDraw);
        
        // Bind IB
        self.font_renderer_index_buffer.?.bind();
        self.font_renderer_index_buffer.?.data(indicies_slice, BufferUsageGl.StaticDraw);

        const font_stride = @intCast(c_longlong, @sizeOf(Vertex)); // 3 (pos(3)) + 2(tex(2)) + 4 (color(r, g, b, a)) + 1 (index(float))

        c.glEnableVertexAttribArray(index_zero);
        
        // Position
        c.glVertexAttribPointer(
            index_zero, 
            3,
            c.GL_FLOAT,
            c.GL_FALSE,
            font_stride,
            @intToPtr(?*anyopaque, 0), // Offset
        );

        c.glEnableVertexAttribArray(index_one);

        // Color
        c.glVertexAttribPointer(
            index_one,
            4,
            c.GL_FLOAT,
            c.GL_FALSE,
            font_stride,
            @intToPtr(?*anyopaque, size_f32 * 3),
        );

        c.glEnableVertexAttribArray(index_two);

        // tex coords
        c.glVertexAttribPointer(
            index_two,
            2,
            c.GL_FLOAT,
            c.GL_FALSE,
            font_stride,
            @intToPtr(?*anyopaque, size_f32 * 7),
        );

        c.glEnableVertexAttribArray(index_three);

        // index
        c.glVertexAttribPointer(
            index_three,
            1,
            c.GL_FLOAT,
            c.GL_FALSE,
            font_stride,
            @intToPtr(?*anyopaque, size_f32 * 9),
        );

        // Unbind VBO
        c.glBindBuffer(c.GL_ARRAY_BUFFER, index_zero);

        // Setup GUI  
        // -----------------------------------------------------------
        self.gui_renderer_vertex_array.?.bind();
        self.gui_renderer_vertex_buffer.?.bind();
        // 6 vertices of 4 floats each
        //self.gui_renderer_vertex_buffer.?.dataless(6 * 4, BufferUsageGl.DynamicDraw);
        self.gui_renderer_vertex_buffer.?.dataV(self.quad_vertex_base, BufferUsageGl.DynamicDraw);
        
        self.gui_renderer_index_buffer.?.bind();
        self.gui_renderer_index_buffer.?.data(indicies_slice, BufferUsageGl.StaticDraw);


        const gui_stride = @intCast(c_longlong, @sizeOf(Vertex));
       
        // Position Attribute
        c.glVertexAttribPointer(
            index_zero, // Which vertex attribute we want to configure
            size_position, // Size of vertex attribute (vec3 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            gui_stride, // Stride
            @intToPtr(?*anyopaque, offset_position), // Offset
        );
        c.glEnableVertexAttribArray(index_zero);

        // Color Attribute
        c.glVertexAttribPointer(
            index_one, // Which vertex attribute we want to configure
            size_color, // Size of vertex attribute (vec2 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            gui_stride, // Stride
            @intToPtr(?*anyopaque, offset_color), // Offset
        );
        c.glEnableVertexAttribArray(index_one);


        // Texture Coordinates Attribute
        c.glVertexAttribPointer(
            index_two, // Which vertex attribute we want to configure
            size_tex_coords, // Size of vertex attribute (vec2 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            gui_stride, // Stride
            @intToPtr(?*anyopaque, offset_tex), // Offset
        );
        c.glEnableVertexAttribArray(index_two);
            
        // Texture Index Attribute
        c.glVertexAttribPointer(
            index_three, // Which vertex attribute we want to configure
            size_index, // Size of vertex attribute (vec2 in this case)
            c.GL_FLOAT, // Type of data
            c.GL_FALSE, // Should the data be normalized?
            gui_stride, // Stride
            @intToPtr(?*anyopaque, offset_index), // Offset
        );
        c.glEnableVertexAttribArray(index_three);

        // Unbind VBO
        c.glBindBuffer(c.GL_ARRAY_BUFFER, index_zero);

        // Unbind the VAO
        c.glBindVertexArray(index_zero);

        // ------------------------------
        
        // Misc initializations

        // Set the clear color
        self.clear_color = Color.rgb(0.2, 0.2, 0.2);
        self.default_draw_color = Color.rgb(1.0, 1.0, 1.0);
 
        // Create the default texture 
        // TODO(devon): Switch from an actual texture to a dataless on with a width and height of (1,1)
        const default_texture_op = try rh.ResourceHandler.loadTexture("default_texture", "assets/textures/t_default.png");
        self.default_texture = default_texture_op orelse return texture.TextureErrors.FailedToLoad;
        
        var samplers = [_]c_int{0} ** MAX_TEXTURE_SLOTS;
        var sampler_index: usize = 0;
        while(sampler_index < MAX_TEXTURE_SLOTS) : (sampler_index += 1) {
            samplers[sampler_index] = @intCast(c_int, sampler_index);
        }
        self.shader_program.?.use();
        self.shader_program.?.setIntArray("texture_slots", samplers[0..], MAX_TEXTURE_SLOTS);
        self.font_renderer_program.?.use();
        self.font_renderer_program.?.setIntArray("texture_slots", samplers[0..], MAX_TEXTURE_SLOTS);
        self.texture_slots[0] = self.default_texture.?.id().id_gl;


        return self;
    }

    /// Frees up any resources that was previously allocated
    pub fn free(allocator: std.mem.Allocator, self: *Self) void {
        // Allow for OpenGL object to de-allocate any memory it needed
        // -- Default
        VertexArrayGl.free(allocator, self.vertex_array.?);
        VertexBufferGl.free(allocator, self.vertex_buffer.?);
        IndexBufferGl.free(allocator, self.index_buffer.?);
        ShaderProgramGl.free(allocator, self.shader_program.?);

        // - Screenbuffer
        VertexArrayGl.free(allocator, self.screenbuffer_vertex_array.?);
        VertexBufferGl.free(allocator, self.screenbuffer_vertex_buffer.?);
        IndexBufferGl.free(allocator, self.screenbuffer_index_buffer.?);
        ShaderProgramGl.free(allocator, self.screenbuffer_program.?);
        Framebuffer.free(allocator, self.screenbuffer.?);
            
        // - Font Renderer
        VertexArrayGl.free(allocator, self.font_renderer_vertex_array.?);
        VertexBufferGl.free(allocator, self.font_renderer_vertex_buffer.?);
        IndexBufferGl.free(allocator, self.font_renderer_index_buffer.?);
        ShaderProgramGl.free(allocator, self.font_renderer_program.?);

        // - GUI Renderer
        VertexArrayGl.free(allocator, self.gui_renderer_vertex_array.?);
        VertexBufferGl.free(allocator, self.gui_renderer_vertex_buffer.?);
        IndexBufferGl.free(allocator, self.gui_renderer_index_buffer.?);
        ShaderProgramGl.free(allocator, self.gui_renderer_program.?);

        // ---
        //self.quad_vertices.deinit();
        allocator.free(self.quad_vertex_base);
        self.screenbuffer_vertices.deinit();
        //self.texture_slots.deinit();
        allocator.free(self.texture_slots);
        
        allocator.destroy(self);

    }
    
    /// Setups up the OpenGL specific components for rendering
    pub fn beginRender(self: *Self, camera: *Camera.Camera2d) void {
       // Bind framebuffer
        self.screenbuffer.?.bind(framebuffa.FramebufferType.Both);

        // Clear the background color
        self.clearColorAndDepth();

        c.glEnable(c.GL_DEPTH_TEST);
        c.glDepthFunc(c.GL_LESS);

        c.glEnable(c.GL_CULL_FACE);
        c.glCullFace(c.GL_BACK);

        const camera_pos = camera.position();
        // const camera_target = camera.targetPosition();
        // const camera_direction = camera_pos.subtract(camera_target).normalize();
        // const camera_right = Vector3.up().cross(camera_direction).normalize();
        // const camera_up = camera_direction.cross(camera_right);
        const camera_zoom = camera.zoom();

        // Set up projection matrix
        const viewport_size = Application.viewportSize();
        // const window_size = Application.windowSize();

        const projection = Matrix4.orthographic(
            0, // Left
            viewport_size.x(), // Right
            0, // top
            viewport_size.y(), // bottom
            -1.0, //Near
            1.0, // Far
        ); 

        // Set up the view matrix
        var view = Matrix4.fromTranslate(camera_pos).scale(Vector3.new(camera_zoom, camera_zoom, 0.0));
        
        self.shader_program.?.use();
        self.shader_program.?.setMatrix4("projection", projection);
        self.shader_program.?.setMatrix4("view", view);
        self.vertex_array.?.bind();

        self.current_program = self.shader_program.?;
        self.current_vertex_array = self.vertex_array.?;
        self.current_vertex_buffer = self.vertex_buffer.?;

        self.beginBatch();
    }

    /// Setups up the OpenGL specific components for rendering
    pub fn beginGui(self: *Self) void {
        // Set up projection matrix
        // const viewport_size = Application.viewportSize();
        const window_size = Application.windowSize();
        const gui_projection = Matrix4.orthographic(
            0, // Left
            window_size.x(), // Right
            0, // top
            window_size.y(), // bottom
            -1.0, //Near
            1.0, // Far
        ); 

        self.gui_renderer_program.?.use();
        self.gui_renderer_program.?.setMatrix4("projection", gui_projection);


        self.font_renderer_program.?.use();
        self.font_renderer_program.?.setMatrix4("projection", gui_projection);
        
        //self.current_program = self.font_renderer_program.?;
        //self.current_vertex_array = self.font_renderer_vertex_array.?;
        //self.current_vertex_buffer = self.font_renderer_vertex_buffer.?;



        self.beginBatch();
    }
    
    /// Handles the framebuffer and clean up for the end of the user-defined render event
    pub fn endRender(self: *Self) void {

        // Submit to Gl
        self.flush();

        // Bind the default frame buffer 
        framebuffa.Framebuffer.resetFramebuffer();

        // Disable depth testing
        c.glDisable(c.GL_DEPTH_TEST);

        self.clearColor();

        // Use screenbuffer's shader program
        self.screenbuffer_program.?.use();

        // Bind screen vao
        self.screenbuffer_vertex_array.?.bind();

        // Bind screenbuffer's texture
        self.screenbuffer.?.bindColorAttachment();

        // Draw the quad
        RendererGl.drawIndexed(6);

        FrameStatistics.incrementQuadCount();
    }

    /// Handles the framebuffer and clean up for the end of the user-defined render event
    pub fn endGui(self: *Self) void {
        
        // Submit to Gl
        self.flush();
    }

    /// Draws geometry with a index buffer
    pub fn drawIndexed(index_count: u32) void {
        const offset = @intToPtr(?*anyopaque, 0);
        //const count: u32 = if (index_count == 0) v
        // Draw 
        c.glDrawElements(
            c.GL_TRIANGLES, // Primitive mode
            @intCast(c_int, index_count), // Number of vertices/elements to draw
            c.GL_UNSIGNED_INT, // Type of values in indices
            offset, // Offset in a buffer or a pointer to the location where the indices are stored
        );

        FrameStatistics.incrementDrawCall();
    }
    
 
    /// Submit the render batch to OpenGl
    pub fn flush(self: *Self) void {
        // If there is nothing queued up to draw, then just leave.
        if(self.index_count == 0) return;
        
        // Bind program
        self.current_program.use();

        // Bind VAO
        self.current_vertex_array.bind();
        
        // Bind VBO
        self.current_vertex_buffer.bind();
        
        // Determine the size of the used portion of the quad vertex array
        const data_size: u32 = @intCast(u32,
            @ptrToInt(self.quad_vertex_ptr) - @ptrToInt(self.quad_vertex_base.ptr)
        );

        // Update the buffer data
        self.current_vertex_buffer.subdataSize(self.quad_vertex_base, data_size);

        // Bind all the batched textures       
        var index: c_uint = 0;
        while(index < self.texture_slot_index) : (index += 1) {
            TextureGl.bindUnit(index, self.texture_slots[index]);
        }

        RendererGl.drawIndexed(self.index_count);
    }
    
    /// Performs the required operations to begin batching
    pub fn beginBatch(self: *Self) void {
        self.index_count = 0;
        self.quad_vertex_ptr = self.quad_vertex_base.ptr;
        self.texture_slot_index = 1;
    }
    
    /// Submits the batch to draw, and begins a new batch.
    pub fn endBatch(self: *Self) void {
        self.flush();
        self.beginBatch();
    }
       
    /// Sets up renderer to be able to draw a untextured quad.
    pub fn drawQuad(self: *Self, position: Vector3) void {
         // Bind Texture
        c.glBindTexture(c.GL_TEXTURE_2D, self.default_texture.?.id().id_gl);

        // Translation * Rotation * Scale
        const transform = Matrix4.fromTranslate(position);

        self.shader_program.?.setMatrix4("model", transform);
        self.shader_program.?.setFloat3("sprite_color", self.default_draw_color.r, self.default_draw_color.g, self.default_draw_color.b);

        // Bind the VAO
        self.vertex_array.?.bind();
        
        RendererGl.drawIndexed(6);

        self.index_count += 6;

        FrameStatistics.incrementQuadCount();
    }
    
    /// Sets up renderer to be able to draw a untextured quad.
    pub fn drawColoredQuad(self: *Self, position: Vector3, size: Vector3, color: Color) void {

        self.checkForProperProgram(self.shader_program.?, self.vertex_buffer.?, self.vertex_array.?);

        const x = position.x();
        const y = position.y();
        const z = position.z();
        const w = size.x();
        const h = size.y();
        //const d = size.z();
        const r = color.r;
        const g = color.g;
        const b = color.b;
        const a = color.a;


        // Bottom Left 
        self.quad_vertex_ptr[0].x = x; 
        self.quad_vertex_ptr[0].y = y; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 0.0;
        self.quad_vertex_ptr[0].v = 0.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;

        // Bottom Right
        self.quad_vertex_ptr[0].x = x + w; 
        self.quad_vertex_ptr[0].y = y; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 1.0;
        self.quad_vertex_ptr[0].v = 0.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;

        // Top Right
        self.quad_vertex_ptr[0].x = x + w; 
        self.quad_vertex_ptr[0].y = y + h; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 1.0;
        self.quad_vertex_ptr[0].v = 1.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;
        
        // Top Left
        self.quad_vertex_ptr[0].x = x; 
        self.quad_vertex_ptr[0].y = y + h; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 0.0;
        self.quad_vertex_ptr[0].v = 1.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;
        
        // ---
        self.index_count += 6;

        FrameStatistics.incrementQuadCount();
    }
    
    /// Sets up renderer to be able to draw a untextured quad.
    pub fn drawColoredQuadGui(self: *Self, position: Vector3, size: Vector3, color: Color) void {
        self.checkForProperProgram(self.gui_renderer_program.?, self.gui_renderer_vertex_buffer.?, self.gui_renderer_vertex_array.?);

        const x = position.x();
        const y = position.y();
        const z = position.z();
        const w = size.x();
        const h = size.y();
        //const d = size.z();
        const r = color.r;
        const g = color.g;
        const b = color.b;
        const a = color.a;


        // Bottom Left 
        self.quad_vertex_ptr[0].x = x; 
        self.quad_vertex_ptr[0].y = y; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 0.0;
        self.quad_vertex_ptr[0].v = 0.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;

        // Bottom Right
        self.quad_vertex_ptr[0].x = x + w; 
        self.quad_vertex_ptr[0].y = y; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 1.0;
        self.quad_vertex_ptr[0].v = 0.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;

        // Top Right
        self.quad_vertex_ptr[0].x = x + w; 
        self.quad_vertex_ptr[0].y = y + h; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 1.0;
        self.quad_vertex_ptr[0].v = 1.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;
        
        // Top Left
        self.quad_vertex_ptr[0].x = x; 
        self.quad_vertex_ptr[0].y = y + h; 
        self.quad_vertex_ptr[0].z = z;
        self.quad_vertex_ptr[0].r = r;
        self.quad_vertex_ptr[0].g = g;
        self.quad_vertex_ptr[0].b = b;
        self.quad_vertex_ptr[0].a = a;
        self.quad_vertex_ptr[0].u = 0.0;
        self.quad_vertex_ptr[0].v = 1.0;
        self.quad_vertex_ptr[0].index = 0;
        self.quad_vertex_ptr += 1;
        
        // ---
        self.index_count += 6;

        FrameStatistics.incrementQuadCount();

        // Use Text Rendering shader program
        //self.gui_renderer_program.?.use();
        //
        //// Pass the quad color
        //self.gui_renderer_program.?.setFloat4("draw_color", color.r, color.g, color.b, color.a);

        //// Activate Texture Slot 0
        //c.glActiveTexture(c.GL_TEXTURE0);

        //// Bind vao
        //self.gui_renderer_vertex_array.?.bind();

        // // Bind Texture
        //c.glBindTexture(c.GL_TEXTURE_2D, self.default_texture.?.id().id_gl);

        //const x = position.x();
        //const y = position.y();
        //const w = size.x();
        //const h = size.y();

        ////zig fmt: off
        //const vertices: [24]f32 = [24]f32 {
        ////  Position                            Texture Coords
        //    x,     y,       0.0, 0.0,
        //    x,   y+h,       0.0, 1.0,
        //    x+w, y+h,       1.0, 1.0,

        //    x,     y,       0.0, 0.0,
        //    x+w, y+h,       1.0, 1.0,
        //    x+w,   y,       1.0, 0.0,
        //};
        //const vertices_slice = vertices[0..];

        //// Update VBO
        //self.gui_renderer_vertex_buffer.?.bind();
        //self.gui_renderer_vertex_buffer.?.subdata(vertices_slice);
        //VertexBufferGl.clearBoundVertexBuffer();

        //// Bind the VAO
        //self.gui_renderer_vertex_array.?.bind();
        //
        //c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        //FrameStatistics.incrementQuadCount();
        //FrameStatistics.incrementDrawCall();
    }

    /// Queues a textured quad to be drawn
    pub fn drawTexturedQuad(self: *Self, texture_region: *TextureRegion, position: Vector3, scale: Vector2, color: Color, flip_h: bool) void {
        // Translation * Rotation * Scale

        // Translation
        var model = Matrix4.fromTranslate(position);

        // Scaling
        const texture_scale = Vector3.fromVector2(scale, 1.0);
        model = model.scale(texture_scale);
        
        // Determine if the sprite has a texture assigned to it
        const texture_id = texture_region.texture().?.id();

        const texture_coordinates = texture_region.textureCoordinates();
    
        // Check to see if the current batch is full
        self.checkBatch();

        // Determine if the sprite's texture id has already been
        // addded to the batch.
        var texture_index = @intToFloat(f32, self.getTextureSlotIndex(texture_id.id_gl));
        texture_index = if(texture_index == -1.0) 0.0 else texture_index;
        
        // If not, then add it.
        if (texture_index == 0.0) {
            texture_index = @intToFloat(f32, self.texture_slot_index);
            const no_errors = self.addTextureToBatch(texture_id.id_gl);
            if(no_errors) {
                self.texture_slot_index += 1;
            }
        }


        const uv_min_x = texture_coordinates[0].x();
        const uv_max_x = texture_coordinates[1].x();

        const r = color.r;
        const g = color.g;
        const b = color.b;
        const a = color.a;

        const vertex_count: usize = 4;
        var vertex_index: usize = 0;

        while(vertex_index < vertex_count) : (vertex_index += 1) {
            const position_4 = Vector4.fromVector3(QUAD_VERTEX_POSITIONS[vertex_index], 1.0);
            const model_position = model.multiplyVec4(position_4);
            const tex_coords = texture_coordinates[vertex_index];

            self.quad_vertex_ptr[0].x = model_position.x(); 
            self.quad_vertex_ptr[0].y = model_position.y(); 
            self.quad_vertex_ptr[0].z = model_position.z();
            self.quad_vertex_ptr[0].r = r;
            self.quad_vertex_ptr[0].g = g;
            self.quad_vertex_ptr[0].b = b;
            self.quad_vertex_ptr[0].a = a;
            self.quad_vertex_ptr[0].u = if(flip_h) uv_min_x + (uv_max_x - tex_coords.x()) else tex_coords.x();
            self.quad_vertex_ptr[0].v = tex_coords.y();
            self.quad_vertex_ptr[0].index = texture_index;

            self.quad_vertex_ptr += 1;
        }

        self.index_count += 6;

        FrameStatistics.incrementQuadCount();
    }

    /// Sets up renderer to be able to draw a Sprite.
    pub fn drawSprite(self: *Self, sprite: *Sprite, position: Vector3) void {

        // Translation * Rotation * Scale

        // Translation
        var model = Matrix4.fromTranslate(position);

        //// Rotation
        //const texture_coords_x = sprite_origin.x() / sprite_size.x();
        //const texture_coords_y = sprite_origin.y() / sprite_size.y();
        //const model_to_origin = Vector3.new(
        //    texture_coords_x,
        //    texture_coords_y,
        //    0.0,
        //);
        //
        //const origin_to_model = Vector3.new(
        //    -texture_coords_x,
        //    -texture_coords_y,
        //    0.0,
        //);

        //// Translate to the selected origin
        //model = model.translate(model_to_origin);
        //// Perform the rotation
        //model = model.rotate(sprite_angle, Vector3.forward());
        //// Translate back
        //model = model.translate(origin_to_model);

        // Scaling
        // const size = sprite.size().?;
        // const sprite_scale = sprite.scale();
        // const w = size.x() * sprite_scale.x();
        // const h = size.y() * sprite_scale.y();
        //const scale = Vector3.new(w, h, 1.0);
        const scale = Vector3.fromVector2(sprite.scale(), 1.0);
        model = model.scale(scale);
        
        // Determine if the sprite has a texture assigned to it
        const texture_id_op = sprite.textureId();
        const texture_id = texture_id_op orelse {
            self.drawQuad(position);
            return;
        };

        const texture_coordinates = sprite.textureRegion().?.textureCoordinates();
    
        // Check to see if the current batch is full
        self.checkBatch();

        // Determine if the sprite's texture id has already been
        // addded to the batch.
        var texture_index = @intToFloat(f32, self.getTextureSlotIndex(texture_id.id_gl));
        texture_index = if(texture_index == -1.0) 0.0 else texture_index;
        
        // If not, then add it.
        if (texture_index == 0.0) {
            texture_index = @intToFloat(f32, self.texture_slot_index);
            const no_errors = self.addTextureToBatch(texture_id.id_gl);
            if(no_errors) {
                self.texture_slot_index += 1;
            }
        }

        const color = sprite.color();
        
        // const sprite_flip = sprite.flipH();
        //const d = size.z();
        const r = color.r;
        const g = color.g;
        const b = color.b;
        const a = color.a;

        const vertex_count: usize = 4;
        var vertex_index: usize = 0;

        while(vertex_index < vertex_count) : (vertex_index += 1) {
            const position_4 = Vector4.fromVector3(QUAD_VERTEX_POSITIONS[vertex_index], 1.0);
            const model_position = model.multiplyVec4(position_4);
            const tex_coords = texture_coordinates[vertex_index];

            self.quad_vertex_ptr[0].x = model_position.x(); 
            self.quad_vertex_ptr[0].y = model_position.y(); 
            self.quad_vertex_ptr[0].z = model_position.z();
            self.quad_vertex_ptr[0].r = r;
            self.quad_vertex_ptr[0].g = g;
            self.quad_vertex_ptr[0].b = b;
            self.quad_vertex_ptr[0].a = a;
            self.quad_vertex_ptr[0].u = tex_coords.x();//if(sprite_flip) 1.0 - tex_coords.x() else tex_coords.x();
            self.quad_vertex_ptr[0].v = tex_coords.y();
            self.quad_vertex_ptr[0].index = texture_index;

            self.quad_vertex_ptr += 1;
        }

        self.index_count += 6;

        FrameStatistics.incrementQuadCount();
    }
    
    /// Sets up the renderer to be able to draw text
    pub fn drawText(self: *Self, text: []const u8, x: f32, y: f32, scale: f32, color: Color) void {
        self.checkForProperProgram(self.font_renderer_program.?, self.font_renderer_vertex_buffer.?, self.font_renderer_vertex_array.?);

        // Loops through and draw
        var text_length = text.len;
        var index: usize = 0;
        var cursor_x = x;

        const r = color.r;
        const g = color.g;
        const b = color.b;
        const a = color.a;
        
        while(index < text_length) : (index += 1) {
            const character: u8 = text[index];
            const current_glyph = app.default_font.?.glyph(character) catch |err| {
                std.debug.print("[Renderer]: Error occurred when retrieving glyph {}! {}\n", .{character, err});
                @panic("[Renderer]: Failed to find glyph!");
            };

            self.checkBatch();

            const texture_id = current_glyph.texture().?.id().id_gl;

            // Determine if the sprite's texture id has already been
            // addded to the batch.
            var texture_index = @intToFloat(f32, self.getTextureSlotIndex(texture_id));
            texture_index = if(texture_index == -1.0) 0.0 else texture_index;
            
            // If not, then add it.
            if (texture_index == 0.0) {
                texture_index = @intToFloat(f32, self.texture_slot_index);
                const no_errors = self.addTextureToBatch(texture_id);
                if(no_errors) {
                    self.texture_slot_index += 1;
                }else {
                    // Submit batch
                }
            }

            const offset = current_glyph.offset();
            const glyph_width = @intToFloat(f32, current_glyph.width());
            const glyph_rows = @intToFloat(f32, current_glyph.rows());
            const x_pos = cursor_x + offset.x() * scale;
            const y_pos = y - (glyph_rows - offset.y()) * scale;
            const advance = current_glyph.advance();
            const width = glyph_width * scale;
            const height = glyph_rows * scale;

            const vertex_count: usize = 4;
            var vertex_index: usize = 0;

            while(vertex_index < vertex_count) : (vertex_index += 1) {
                const v_position = QUAD_VERTEX_POSITIONS[vertex_index];
                const tex_coords = QUAD_TEXTURE_UV[vertex_index];
                const vx = v_position.x();
                const vy = v_position.y();
                const vz = v_position.z();

                const vu = tex_coords.x();
                const vv = tex_coords.y();

                self.quad_vertex_ptr[0].x = if(vx == 0.0) x_pos else x_pos + width; 
                self.quad_vertex_ptr[0].y = if(vy == 0.0) y_pos else y_pos + height; 
                self.quad_vertex_ptr[0].z = vz;
                self.quad_vertex_ptr[0].r = r;
                self.quad_vertex_ptr[0].g = g;
                self.quad_vertex_ptr[0].b = b;
                self.quad_vertex_ptr[0].a = a;
                self.quad_vertex_ptr[0].u = vu;
                self.quad_vertex_ptr[0].v = if(vv == 0.0) 1.0 else 0.0;
                self.quad_vertex_ptr[0].index = texture_index;

                self.quad_vertex_ptr += 1;
            }

            const shifted = @intToFloat(f32, (advance >> 6)) * scale;

            // Advance the cursor
            cursor_x += shifted;

            self.index_count += 6;

            FrameStatistics.incrementQuadCount();
        }

       
    }

    /// Changes to clear color
    pub fn changeClearColor(self: *Self, color: Color) void {
        self.clear_color = color;
    }
    
    /// Clears the background with the set clear color
    pub fn clearColorAndDepth(self: *Self) void {
        c.glClearColor(self.clear_color.r, self.clear_color.g, self.clear_color.b, self.clear_color.a);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    }

    /// Clears the background with the set clear color and no DEPTH buffer
    pub fn clearColor(self: *Self) void {
        c.glClearColor(self.clear_color.r, self.clear_color.g, self.clear_color.b, self.clear_color.a);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
    }
    
    /// Request to disable byte_alignment restriction
    pub fn setByteAlignment(self: *Self, packing_mode: PackingMode, byte_alignment: ByteAlignment) void {
        _ = self;
        const pack_type = switch(packing_mode) {
            PackingMode.Pack => @enumToInt(GlPackingMode.Pack),
            PackingMode.Unpack => @enumToInt(GlPackingMode.Unpack),
        };
        const alignment: c_int = switch(byte_alignment) {
            ByteAlignment.One => 1,
            ByteAlignment.Two => 2,
            ByteAlignment.Four => 4,
            ByteAlignment.Eight => 8,
        };

        c.glPixelStorei(pack_type, alignment);
    }

    /// Clears out the currently bound texture
    pub fn clearBoundTexture() void {
        c.glBindTexture(c.GL_TEXTURE_2D, 0);
    }
    
    // Batch-related functions/methods
    // -----------------------------------

    /// Adds a texture to the texture batch, if the unique texture ID
    /// was not already added into the set.
    /// Returns true if no errors occurred.
    pub fn addTextureToBatch(self: *Self, id: c_uint) bool {
        if(self.texture_slot_index >= MAX_TEXTURE_SLOTS) return false;
        self.texture_slots[self.texture_slot_index] = id;
        return true;
    }

    /// Returns whether or not the texture_slots is already at maximum capacity
    /// Returns true if the batch is already at MAX_TEXTURE_SLOTS.
    /// Otherwise, false.
    pub fn checkTextureSlots(self: *Self) bool {
        if(self.texture_slots.len >= MAX_TEXTURE_SLOTS) return true;
        return false;
    }

    /// Returns whether or not the passed `id` is already
    /// in the texture slot set.
    pub fn containsTextureId(self: *Self, id: c_uint) bool {
        for(self.texture_slots) | slot_id | {
            if(slot_id == id) return true;
        }

        return false;
    }

    /// Returns the index of the texture id, if found in the 
    /// set. Otherwise, it'll return -1.
    pub fn getTextureSlotIndex(self: *Self, id: c_uint) i8 {
        var index: i8 = -1;
        var counter: usize = 0;
        while(counter < self.texture_slot_index) : (counter += 1) {
            if(self.texture_slots[counter] == id) {
                index = @intCast(i8, counter);
                break;
            }
        }

        return index;
    }

    /// Checks to see if the batch maximum bounds have
    /// already been reached, if so, then the old batch
    /// will be submitted for render, and a new batch will
    /// begin.
    pub fn checkBatch(self: *Self) void {
        if(self.index_count >= MAX_INDICES or self.texture_slot_index >= MAX_TEXTURE_SLOTS) self.endBatch();
    }

    /// Checks to ensure that the currently bound shader program 
    /// is the one that will be used for the current render command.
    /// If not, then it will submit the current batch to the renderer.
    /// Then set the proper shader program, vertex buffer, and vertex array.
    fn checkForProperProgram(self: *Self, program: *ShaderProgramGl, vertex_buffer: *VertexBufferGl, vertex_array: *VertexArrayGl) void {
        if(self.current_program != program) {
            self.endBatch();

            self.current_program = program;
            self.current_vertex_buffer = vertex_buffer;
            self.current_vertex_array = vertex_array;
        }
    }

    // -----------------------------------
    
};

/// Resizes the viewport to the given size and position 
/// Comments: This is for INTERNAL use only.
pub fn resizeViewport(x: c_int, y: c_int, width: c_int, height: c_int) void {
    c.glViewport(x, y, width, height);
}

