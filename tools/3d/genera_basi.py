#!/usr/bin/env python3
"""Generate dimensionally exact, watertight prototype tabletop bases.
No copyrighted artwork is embedded; these are blank geometry templates.
Usage:
  python3 tools/3d/genera_basi.py hex --across-flats 90 --height 3 --output hex_90.stl
  python3 tools/3d/genera_basi.py disc --diameter 25 --height 4 --output pedina_25.stl
"""
import argparse
import math
from pathlib import Path

def triangle(a, b, c):
    u = [b[i] - a[i] for i in range(3)]
    v = [c[i] - a[i] for i in range(3)]
    n = (u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0])
    norm = math.sqrt(sum(x*x for x in n)) or 1.0
    return (tuple(x/norm for x in n), a, b, c)

def prism(sides, radius, height, start_angle):
    bottom = [(radius*math.cos(start_angle+2*math.pi*i/sides),
               radius*math.sin(start_angle+2*math.pi*i/sides), 0.0)
              for i in range(sides)]
    top = [(x, y, height) for x, y, _ in bottom]
    cb, ct = (0.0, 0.0, 0.0), (0.0, 0.0, height)
    out = []
    for i in range(sides):
        j = (i+1)%sides
        out += [triangle(ct, top[i], top[j]),
                triangle(cb, bottom[j], bottom[i]),
                triangle(bottom[i], bottom[j], top[j]),
                triangle(bottom[i], top[j], top[i])]
    return out

def write_ascii_stl(path, name, tris):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open('w', encoding='ascii', newline='\n') as f:
        f.write('solid '+name+'\n')
        for n, a, b, c in tris:
            f.write('  facet normal %.9g %.9g %.9g\n    outer loop\n' % n)
            for v in (a, b, c):
                f.write('      vertex %.9g %.9g %.9g\n' % v)
            f.write('    endloop\n  endfacet\n')
        f.write('endsolid '+name+'\n')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('shape', choices=('hex','disc'))
    p.add_argument('--across-flats', type=float, default=90.0,
                   help='Hex flat-to-flat dimension in millimeters')
    p.add_argument('--diameter', type=float, default=25.0)
    p.add_argument('--height', type=float, default=3.0)
    p.add_argument('--output', default='base.stl')
    args = p.parse_args()
    if args.height <= 0 or args.across_flats <= 0 or args.diameter <= 0:
        p.error('All measurements must be positive')
    if args.shape == 'hex':
        # For a regular flat-top hexagon, apothem = sqrt(3)*radius/2.
        radius = args.across_flats / math.sqrt(3.0)
        tris = prism(6, radius, args.height, 0.0)
    else:
        tris = prism(64, args.diameter/2.0, args.height, 0.0)
    write_ascii_stl(args.output, args.shape+'_base', tris)
    print('%s: %d triangles, %s' % (args.output, len(tris), args.shape))

if __name__ == '__main__':
    main()
