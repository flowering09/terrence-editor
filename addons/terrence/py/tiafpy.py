import struct
import sys
import os


def read_tiaf(path):

    with open(path, "rb") as f:
        data = f.read()

    offset = 0

    magic = data[offset:offset+4]
    offset += 4

    if magic != b"TIAF":
        raise Exception("Invalid TIAF")

    version, = struct.unpack_from("<I", data, offset)
    offset += 4

    if version != 1:
        raise Exception("Unsupported TIAF version")


    frame_count, vertex_count, index_count = struct.unpack_from(
        "<III",
        data,
        offset
    )

    offset += 12


    frames = []

    vertex_size = struct.calcsize("<8f4B")

    for frame in range(frame_count):

        vertices = []

        for i in range(vertex_count):

            vertex = struct.unpack_from(
                "<8f4B",
                data,
                offset
            )

            offset += vertex_size

            vertices.append(vertex)

        frames.append(vertices)


    indices = []

    for i in range(index_count):

        index, = struct.unpack_from(
            "<H",
            data,
            offset
        )

        offset += 2

        indices.append(index)


    return frames, indices



def write_vertex(f, v):

    x,y,z,nx,ny,nz,u,vv,r,g,b,a = v

    f.write(
        "    { "
        f"{x:.6f}f, {y:.6f}f, {z:.6f}f, "
        f"{nx:.6f}f, {ny:.6f}f, {nz:.6f}f, "
        f"{u:.6f}f, {vv:.6f}f, "
        f"{r}, {g}, {b}, {a}"
        " },\n"
    )



def write_header(path, name, frames, indices):

    with open(path, "w") as f:

        f.write("#pragma once\n\n")


        for i, frame in enumerate(frames):

            f.write(
                f"static Vertex {name}_frame_{i}[] = {{\n"
            )

            for vertex in frame:
                write_vertex(f, vertex)

            f.write("};\n\n")


        f.write(
            f"static Vertex* {name}_frames[] = {{\n"
        )

        for i in range(len(frames)):

            f.write(
                f"    {name}_frame_{i},\n"
            )

        f.write("};\n\n")


        f.write(
            f"static unsigned short {name}_indices[] = {{\n"
        )

        for i in range(0, len(indices), 3):

            f.write(
                "    "
                + ", ".join(
                    str(x)
                    for x in indices[i:i+3]
                )
                + ",\n"
            )

        f.write("};\n\n")


        f.write(
f"""static MeshAnimation {name}_animation = {{
    {name}_frames,
    {len(frames)},
    {name}_indices,
    {len(indices)}
}};
"""
        )



if __name__ == "__main__":

    if len(sys.argv) < 3:
        print(
            "usage: tiafpy.py input.tiaf output.h"
        )
        sys.exit(1)


    input_file = sys.argv[1]
    output_file = sys.argv[2]

    name = os.path.splitext(
        os.path.basename(output_file)
    )[0]


    frames, indices = read_tiaf(input_file)

    write_header(
        output_file,
        name,
        frames,
        indices
    )

    print(
        "Built",
        output_file
    )