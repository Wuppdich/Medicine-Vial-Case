include <BOSL2/std.scad>
include <threadlib/threadlib.scad>

start_angle = 30;
bottom_r = 30;
// in mm/1°
goemboec_rate_small = 0.1;
goemboec_rate_big = 0.2;
goemboec_end_angle = 120;
goemboec_step = 5;
ribs = 3;

ORIGIN = [0, 0, 0];

function to3d(points) = [for (p=points) [each p, 0]];

function goemboec(start_r, rate=0.1, start_angle=0, end_angle=180) = [
    for (a=[start_angle:$fa:end_angle])
        polar_to_xy(start_r + rate * (a - start_angle), a)
];

// https://www.paulinternet.nl/?page=bicubic

// returns the y value of a third degree polynomial at x, given the coefficients.
// coefficients: list of coefficients a, b, c and d
// x: x-value to calculate y for.
// RETURN: the y-value of a third degree polynomial at x
function f3(coefficients, x) = coefficients[0] * pow(x, 3)
    + coefficients[1] * pow(x, 2)
    + coefficients[2] * x
    + coefficients[3];

// returns a list of coefficients for a third degree polynomial
function cubic_coeff(x1, x2, y1, y2, k1, k2) = let(
        a1 = (k1 + k2) * (x1 - x2) - 2 * y1 + 2 * y2,
        a2 = pow(x1 - x2, 3),
        a = a1 / a2,
        b11 = k1 * (x1 - x2) * (x1 + 2 * x2),
        b12 = k2 * (-2 * pow(x1, 2) + x1 * x2 + pow(x2, 2)),
        b13 = 3 * (x1 + x2) * (y1 - y2),
        b2 = pow(x1 - x2, 3),
        b = (-b11 + b12 + b13) / b2,
        c11 = k2 * x1 * (x1 - x2) * (x1 + 2 * x2),
        c12 = k1 * (-2 * pow(x1, 2) + x1 * x2 + pow(x2, 2)),
        c13 = 6 * x1 * (y1 - y2),
        c2 = pow(x1 -x2, 3),
        c = (c11 - x2 * (c12 + c13)) / c2,
        d11 = x1 * (-x1 + x2) * (k2 * x1 + k1 * x2),
        d12 = x2 * (-3 * x1 + x2) * y1,
        d13 = pow(x1, 2) * (x1 - 3 * x2) * y2,
        d2 = pow(x1 -x2, 3),
        d = (x2 * (d11 - d12) + d13) / d2
    )
    [a, b, c, d];

function cubic_points(points, k1 = 0, k2 = 0) = let(
        coeff = cubic_coeff(points[0].x,
                            points[1].x,
                            points[0].y,
                            points[1].y,
                            k1, k2),
        d_x = points[1].x - points[0].x,
        step = d_x / floor(d_x / $fs),
        i_range = [points[0].x : step : points[1].x]
    )
    [for (x=i_range) [x, f3(coeff, x)]];

small_arc = yrot(90, p=to3d(goemboec(start_r=bottom_r,
                                    rate=goemboec_rate_small,
                                    start_angle=start_angle)));
big_arc = yrot(90, xrot(360 / (ribs * 2), p=to3d(goemboec(start_r=bottom_r,
                                                rate=goemboec_rate_big,
                                                start_angle=start_angle))));

function flip_pairwise(list) = [for (e=list) [e[1], e[0]]];

function polar_cubic_3d(points) = let(
        plane_n = plane_normal(plane=plane_from_points(
                points=[[0, 0, 0], each points]))
    )
    rot(from=UP, to=plane_n,
        p=to3d(polar_to_xy(flip_pairwise(cubic_points(
            sort(flip_pairwise(xy_to_polar(
                rot(from=plane_n, to=UP, p=points))),0), $fs=5)))));

function zip(a, b) = [for (i=[0 : min(len(a), len(b)) - 1]) [a[i], b[i]]];

// stroke(small_arc);
// stroke(big_arc);

// %stroke(polar_cubic_3d([small_arc[6], big_arc[6]]));

// rot_copies(UP, n=5, delta=30*BACK) circle(10);

// xrot_copies(n=ribs) hull_points(points=[each small_arc, each big_arc]);


points = [for (e=zip(small_arc, big_arc)) polar_cubic_3d([each e])];
zrot_copies(n=ribs) mirror_copy(RIGHT) stroke([for (r=points) each r]);

