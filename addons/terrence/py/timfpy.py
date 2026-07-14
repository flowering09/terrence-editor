import struct
import sys
import os


def read_timf(path):

    with open(path, "rb") as f:
        data = f.read()

    offset = 0

    magic = data[offset:offset+4]
    offset += 4

    if magic != b"TIMF":
        raise Exception("Invalid TIMF")

    version, = struct.unpack_from("<I", data, offset)
    offset += 4

    if version != 1:
        raise Exception("Unsupported TIMF version")


    vertex_count, index_count = struct.unpack_from(
        "<II",
        data,
        offset
    )

    offset += 8


    vertices = []

    for _ in range(vertex_count):

        values = struct.unpack_from(
            "<8f4B",
            data,
            offset
        )

        offset += struct.calcsize("<8f4B")

        vertices.append(values)


    indices = []

    for _ in range(index_count):

        index, = struct.unpack_from(
            "<H",
            data,
            offset
        )

        offset += 2

        indices.append(index)


    return vertices, indices



def write_header(path, name, vertices, indices):

    with open(path, "w") as f:

        f.write("#pragma once\n\n")


        f.write(
            f"static Vertex {name}_vertices[] = {{\n"
        )

        for v in vertices:

            x,y,z,nx,ny,nz,u,vv,r,g,b,a = v

            f.write(
                "    { "
                f"{x:.6f}f, {y:.6f}f, {z:.6f}f, "
                f"{nx:.6f}f, {ny:.6f}f, {nz:.6f}f, "
                f"{u:.6f}f, {vv:.6f}f, "
                f"{r}, {g}, {b}, {a}"
                " },\n"
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
f"""static Mesh {name}_mesh = {{
    {name}_vertices,
    {len(vertices)},
    {name}_indices,
    {len(indices)}
}};
"""
        )



if __name__ == "__main__":

    if len(sys.argv) < 3:
        print(
            "usage: timfpy.py input.timf output.h"
        )
        exit(1)


    input_file = sys.argv[1]
    output_file = sys.argv[2]

    name = os.path.splitext(
        os.path.basename(output_file)
    )[0]


    vertices, indices = read_timf(input_file)

    write_header(
        output_file,
        name,
        vertices,
        indices
    )

    print(
        f"Built {output_file}"
    )