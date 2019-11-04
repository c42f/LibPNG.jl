const PNG_BYTES_TO_CHECK = 8

const PNG_COLOR_MASK_PALETTE = 1
const PNG_COLOR_MASK_COLOR = 2
const PNG_COLOR_MASK_ALPHA = 4

const PNG_COLOR_TYPE_GRAY = 0
const PNG_COLOR_TYPE_RGB = PNG_COLOR_MASK_COLOR        # 2
const PNG_COLOR_TYPE_PALETTE = PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_PALETTE # 3
const PNG_COLOR_TYPE_GRAY_ALPHA = PNG_COLOR_MASK_ALPHA # 4
const PNG_COLOR_TYPE_RGB_ALPHA = PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_ALPHA # 6
const PNG_COLOR_TYPE_RGBA = PNG_COLOR_TYPE_RGB_ALPHA   # 6

function png_error_handler(::Ptr{Nothing}, msg::Cstring)
    error("Png error: $msg")
end

function png_warn_handler(::Ptr{Nothing}, msg::Cstring)
    warn("Png warn: $msg")
end
const png_error_fn = @cfunction(png_error_handler, Nothing, (Ptr{Nothing}, Cstring))
const png_warn_fn = @cfunction(png_warn_handler, Nothing, (Ptr{Nothing}, Cstring))

# Returns the libpng version string
function get_libpng_version()
    ver = ccall((:png_access_version_number, libpng), Cuint, ())
    # Version in the format of xxyyzz, where x=major, yy=minor, z=release
    # But on the major version the first x is excluded if 0.
    dig = digits(ver)[end:-1:1]
    length(dig) == 5 ? prepend!(dig, 0) : error("Unknown libpng version: $ver")

    @inbounds major = dig[1] == 0 ? string(dig[2]) : string(dig[1], dig[2])
    @inbounds minor = dig[3] == 0 ? string(dig[4]) : string(dig[3], dig[4])
    @inbounds release = dig[5] == 0 ? string(dig[6]) : string(dig[5], dig[6])

    ver_string = "$major.$minor.$release"
end

const PNG_LIBPNG_VER_STRING = get_libpng_version()

function open_png(filename::String)
    fp = ccall(:fopen, Ptr{Nothing}, (Cstring, Cstring), filename, "rb")
    fp == C_NULL && error("Failed to open $filename")

    header = zeros(UInt8, PNG_BYTES_TO_CHECK)
    header_size = ccall(:fread, Csize_t, (Ptr{UInt8}, Cint, Cint, Ptr{Nothing}), header, 1, PNG_BYTES_TO_CHECK, fp)
    header_size != 8 && error("Failed to read header from $filename")

    is_png = ccall((:png_sig_cmp, libpng), Cint, (Ptr{UInt8}, Csize_t, Csize_t), header, 0, PNG_BYTES_TO_CHECK)
    is_png != 0 && error("File $filename is not a png file")

    return fp
end

function create_read_struct()
    png_ptr = ccall((:png_create_read_struct, libpng), Ptr{Nothing}, (Cstring, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}),
                    PNG_LIBPNG_VER_STRING, C_NULL, png_error_fn, png_warn_fn)
    png_ptr == C_NULL && error("Failed to create png read struct")
    return png_ptr
end

function create_info_struct(png_ptr)
    info_ptr = ccall((:png_create_info_struct, libpng), Ptr{Nothing}, (Ptr{Nothing},), png_ptr)
    info_ptr == C_NULL && error("Failed to create png info struct")
    return info_ptr
end

function png_init_io(png_ptr::Ptr{Nothing}, fp::Ptr{Nothing})
    ccall((:png_init_io, libpng), Nothing, (Ptr{Nothing}, Ptr{Nothing}), png_ptr, fp)
end

function png_set_sig_bytes(png_ptr::Ptr{Nothing})
    ccall((:png_set_sig_bytes, libpng), Nothing, (Ptr{Nothing}, Cint), png_ptr, PNG_BYTES_TO_CHECK)
end

function png_read_png(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing}, transforms::Int)
    ccall((:png_read_png, libpng), Nothing, (Ptr{Nothing}, Ptr{Nothing}, Cint, Ptr{Nothing}), png_ptr, info_ptr, transforms, C_NULL)
end

function png_destroy_read_struct(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    png_ptr_ptr = Ref{Ptr{Nothing}}(png_ptr)
    info_ptr_ptr = Ref{Ptr{Nothing}}(info_ptr)
    ccall((:png_destroy_read_struct, libpng), Nothing, (Ref{Ptr{Nothing}}, Ref{Ptr{Nothing}}, Ptr{Ptr{Nothing}}), png_ptr_ptr, info_ptr_ptr, C_NULL)
end

function close_png(fp::Ptr{Nothing})
    ccall(:fclose, Cint, (Ptr{Nothing},), fp)
end

function png_get_image_width(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    ccall((:png_get_image_width, libpng), UInt32, (Ptr{Nothing}, Ptr{Nothing}), png_ptr, info_ptr)
end

function png_get_image_height(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    ccall((:png_get_image_height, libpng), UInt32, (Ptr{Nothing}, Ptr{Nothing}), png_ptr, info_ptr)
end

function png_get_color_type(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    ccall((:png_get_color_type, libpng), UInt32, (Ptr{Nothing}, Ptr{Nothing}), png_ptr, info_ptr)
end

function png_get_bit_depth(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    ccall((:png_get_bit_depth, libpng), UInt32, (Ptr{Nothing}, Ptr{Nothing}), png_ptr, info_ptr)
end

function png_get_channels(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    ccall((:png_get_channels, libpng), UInt8, (Ptr{Nothing}, Ptr{Nothing}), png_ptr, info_ptr)
end


# Write functions

function png_create_write_struct(png_error_fn::Ptr{Nothing}, png_warn_fn::Ptr{Nothing})
    png_ptr = ccall((:png_create_write_struct, libpng), Ptr{Nothing}, (Cstring, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}),
                    PNG_LIBPNG_VER_STRING, C_NULL, png_error_fn, png_warn_fn)
    png_ptr == C_NULL && error("Failed to create png write struct")
    return png_ptr
end

function png_create_info_struct(png_ptr::Ptr{Nothing})
    info_ptr = ccall((:png_create_info_struct, libpng), Ptr{Nothing}, (Ptr{Nothing},), png_ptr)
    info_ptr == C_NULL && error("Failed to create png info struct")
    return info_ptr
end

function png_write_info(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    ccall((:png_write_info, libpng), Nothing, (Ptr{Nothing}, Ptr{Nothing}), png_ptr, info_ptr)
end

function png_destroy_write_struct(png_ptr::Ptr{Nothing}, info_ptr::Ptr{Nothing})
    png_ptr_ptr = Ref{Ptr{Nothing}}(png_ptr)
    info_ptr_ptr = Ref{Ptr{Nothing}}(info_ptr)
    ccall((:png_destroy_write_struct, libpng), Nothing, (Ref{Ptr{Nothing}}, Ref{Ptr{Nothing}}), png_ptr_ptr, info_ptr_ptr)
end
