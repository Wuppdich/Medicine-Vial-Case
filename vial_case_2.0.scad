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

// returns the coefficients for a third degree polynomial to go through two points at x == 0 and x == 1 at a defined gradient
//  RETURNS: list of coefficients a, b, c and d for a third degree polynomial.
function catmull_rom_coeff(points) = let(
        d0 = (points[2].y - points[0].y) / 2,
        d1 = (points[3].y - points[1].y) / 2,
        a = 2 * points[1].y - 2 * points[2].y + d0 + d1,
        b = -3 * points[1].y + 3 * points[2].y - 2 * d0 - d1,
        c = d0,
        d = points[1].y
    )
    [a, b, c, d];

function catmull_rom(points) = let(
        // we scale the x-values down so point 2 and 3 are on x=0 and x=1 respectively.
        // doing so massively reduces the coefficient calculation and is sufficient for our use case
        x_scalar = points[2].x - points[1].x,
        coeff = catmull_rom_coeff(xscale(1 / x_scalar, points)),
        step = 1 / floor(1 / ($fs / (x_scalar * 10))),
        i_range = [0 : step : 1]
    )
    right(points[1].x, xscale(x=x_scalar, p=[for (x=i_range) [x, f3(coeff, x)]]));

// goemboec muss umgeschrieben werden, sodass zusammenhängende punkte von verschiedenen
// kurven auf einer Ebene gesampled werden
small_arc = to3d(goemboec(start_r=bottom_r, rate=goemboec_rate_small, start_angle=start_angle));
big_arc = xrot(360 / (ribs * 2), p=to3d(goemboec(start_r=bottom_r, rate=goemboec_rate_big, start_angle=start_angle)));

// rot_copies(UP, n=5, delta=30*BACK) circle(10);

// xrot_copies(n=ribs) hull_points(points=[each small_arc, each big_arc]);

stroke(small_arc);
stroke(big_arc);

// smoothed_points = catmull_rom_path([small_arc2[0], big_arc2[0], small_arc[0], big_arc[0]]);
// echo(smoothed_points);
// color("green") stroke(smoothed_points);
