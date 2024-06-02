use <threadlib/threadlib.scad> // https://github.com/adrianschlatter/threadlib
use <scad-utils/morphology.scad> // https://github.com/openscad/scad-utils
use <scad-utils/mirror.scad>
use <Alice-OpenSCAD-Lib/lib.scad>  // https://github.com/Wuppdich/Alice-OpenSCAD-Lib
use <Alice-OpenSCAD-Lib/logo.scad>

$fn=120;

vial_diameter = 22.6;
vial_height = 49.0;
// The top of the thread will end at this height of the content/vial.
vial_neck_start = 34.0;
// Make this value smaller than any rounded edges of the contents/vials
vial_rounding = 2.5;
// Clearance applied around the contents/vial and in various places. Set this to your 3D-printers printing/manufacturing tolerance
clearance = 0.15;
wall_thickness = 4.0;
// Chose one thread from threadlib's THREAD_TABLE.scad, without the -ext/-int extension. (https://github.com/adrianschlatter/threadlib/blob/develop/THREAD_TABLE.scad)
thread_type = "M28x2";
thread_height = 7.0;
thread_cut = 1.5;
thread_fillet_r = 2;
// Bottom/top start angle of rounded edges for easier 3D-printing. set this to zero for full rounded edges.
case_roundings_start_angle = 30;
// Moves the origin of the case's rounding up to make it a bit slimmer
case_roundings_offset = 1.2;
// Additional clearance to the threads (useful for 3D-prints)
thread_add_clearance = 0.07;
// Defines minimum flat surface next to roundings in some places. For 3D-printing; Keeps some details bigger than the nozzle.
min_flat_of_roundings = 0.45;
//draw the top logo
top_logo = true;
// generate top part/cap
top = true;
// generate bottom part
bottom = true;
// for debug purposes / marvelling at the shapes
cut_view = false;

bottom_thread_designator = str(thread_type, "-ext");
// bottom thread specs
bts = thread_specs(bottom_thread_designator);
top_thread_designator = str(thread_type, "-int");
// top thread specs
tts = thread_specs(top_thread_designator);
thread_table = [[bottom_thread_designator, [bts[0], bts[1], bts[2],
                    [[bts[3][0][0], bts[3][0][1] + thread_add_clearance],
                    [bts[3][1][0], bts[3][1][1] - thread_add_clearance],
                    [bts[3][2][0] - thread_add_clearance, bts[3][2][1]],
                    [bts[3][3][0] - thread_add_clearance, bts[3][3][1]]]]],
                [top_thread_designator, [tts[0], tts[1], tts[2],
                    [[tts[3][0][0], tts[3][0][1] - thread_add_clearance],
                    [tts[3][1][0], tts[3][1][1] + thread_add_clearance],
                    [tts[3][2][0] - thread_add_clearance, tts[3][2][1]],
                    [tts[3][3][0] - thread_add_clearance, tts[3][3][1]]]]]];

inner_wall_r = vial_diameter / 2 + clearance;
outer_wall_r = vial_diameter / 2 + wall_thickness + clearance;

bottom_thread_pitch = bts[0];
bottom_thread_turns = (thread_height - bottom_thread_pitch - thread_cut) / bottom_thread_pitch;
bottom_thread_diameter = bts[2];
bottom_thread_support = bottom_thread_diameter / 2 - inner_wall_r;
bottom_height = vial_neck_start + wall_thickness + clearance;

top_thread_pitch = tts[0];
top_thread_turns = (thread_height - top_thread_pitch) / top_thread_pitch;
top_thread_diameter = tts[2];
top_thread_support = outer_wall_r - top_thread_diameter / 2;

thread_start_height = bottom_height - thread_height;
case_height = vial_height + (wall_thickness + clearance) * 2;
thread_width = top_thread_diameter - bottom_thread_diameter;

// debug
echo(str("cap thread wall thickness: ", top_thread_support));
echo(str("bottom thread wall thickness: ", bottom_thread_support ));

difference() {
    union() {

        if(top) {case_top();}
        if(bottom) {case_bottom();}

    }
    if (cut_view) {translate([0, 0, -0.1]) linear_extrude(case_height + 0.2) square(size=[outer_wall_r, outer_wall_r]);}
}

module case_top() {
    difference() {
        rotate_extrude(convexity=4) shape_top();
        case_cuts();
        if (top_logo) {translate([0, 0, case_height - 0.2]) linear_extrude(0.4) scale([1.04, 1.04, 1]) Logo();}
    }
    // threads
    difference() {
        translate([0, 0, thread_start_height + thread_cut + top_thread_pitch / 2])
            thread(top_thread_designator, turns=top_thread_turns, table=thread_table);
        translate([0, 0, thread_start_height + thread_cut])
            linear_extrude(thread_height - thread_cut) copy_rotate(3)
                translate([bottom_thread_diameter / 2, -thread_width / (2 * sin(45)), 0]) rotate(45) 
                    square(thread_width);
    }
}

module case_bottom() {
    difference() {
        rotate_extrude(convexity=4) shape_bottom();
        case_cuts();
        // logo
        translate([0, 0, -0.2]) linear_extrude(0.4) scale([-1.04, 1.04, 1]) Logo();        
    }
    // thread
    difference() {
        translate([0, 0, thread_start_height + thread_cut + bottom_thread_pitch / 2])
            thread(bottom_thread_designator, turns=bottom_thread_turns, table=thread_table);
        translate([0, 0, thread_start_height + thread_cut])
            linear_extrude(thread_height - thread_cut) copy_rotate(3)
            translate([top_thread_diameter / 2, -thread_width * sin(45), 0]) rotate(45) square(thread_width);
    }
}

module shape_top() {
    difference() {
        case_shape();
        square([outer_wall_r, thread_start_height]);
        fillet(top_thread_support - min_flat_of_roundings) translate([inner_wall_r, thread_start_height, 0]) union() {
            rounding(thread_fillet_r) translate([-thread_fillet_r - top_thread_support, -thread_fillet_r + clearance, 0])
                square([thread_fillet_r + wall_thickness, thread_fillet_r + thread_height]);
            translate([0, -1, 0]) square([wall_thickness, 1]);
            translate([-1, 0, 0]) square([1, thread_height + top_thread_support]);
        }
    }
}

module shape_bottom() {
    difference() {
        case_shape();
        translate([0, bottom_height, 0]) square([outer_wall_r, case_height]);
        fillet(bottom_thread_support - min_flat_of_roundings) translate([inner_wall_r - 1, bottom_height, 0]) union() {
            square([wall_thickness + 1, 1]);
            translate([0, -thread_height, 0]) square([1, thread_height]);
        }
        translate([inner_wall_r + bottom_thread_support, thread_start_height, 0])
            rounding(thread_fillet_r) translate([0, 0, 0]) square([thread_fillet_r + wall_thickness, thread_fillet_r + thread_height]);
    }
}

module case_shape() {
    difference() {
        case_outer_volume();
        case_inner_volume();
    } 
}

module case_outer_volume() {
    corner_r = vial_rounding + wall_thickness + case_roundings_offset;
    translate([0, case_height / 2, 0]) mirror_y() translate([0, -case_height / 2, 0]) union() {
        // top/bottom face
        square([outer_wall_r - corner_r, case_height / 2]);
        // side walls
        translate([0, cos(case_roundings_start_angle) * corner_r, 0]) square([outer_wall_r, case_height / 2]);
        // 3D printable rounded corner
        translate([outer_wall_r - corner_r, cos(case_roundings_start_angle) * corner_r, 0]) difference() {
            circle(r=corner_r);
            translate([0, - corner_r - cos(case_roundings_start_angle) * corner_r, 0])
                square(corner_r * 2, center=true);
        }
    }
}

module case_inner_volume() {
    case_inner_height = vial_height + clearance * 2;
    translate([0, wall_thickness - clearance, 0]) union() {
        // rounded corner
        rounding(r=vial_rounding) square([inner_wall_r, case_inner_height]);
        // center fill
        square([inner_wall_r / 2, case_inner_height]);
    }
}

module case_cuts() {
    // inner
    translate([0, 0, wall_thickness + vial_rounding])
        linear_extrude(vial_height - vial_rounding * 2, convexity=4) copy_rotate(18) union() {
            translate([inner_wall_r - 0.25, 0, 0]) rotate(45) square(1, center=true);
        }
}