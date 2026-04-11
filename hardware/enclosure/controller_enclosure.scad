/*
 * controller_enclosure.scad
 *
 * 3D-printable enclosure for the assembled nebulizer controller PCB.
 * Features integrated adapter dock with dovetail mount for cup adapters.
 *
 * Designed for a JLCPCB-assembled PCB (see docs/JLCPCB_ORDERING_GUIDE.md)
 * but also works with a perfboard build.
 *
 * USAGE:
 *   1. Measure your assembled PCB and update dimensions below
 *   2. Choose your power connector type (USB-C, barrel jack, or battery)
 *   3. Preview (F5), Render (F6), Export STL
 *   4. Print BOTH the base and lid
 *   5. Print in PETG for best durability and chemical resistance
 *
 * License: MIT
 */

/* =====================================================================
 * PCB DIMENSIONS
 *
 * Measure your assembled PCB (or use the reference design dimensions).
 * Include any components that stick up above the board surface.
 * ===================================================================== */

pcb_width           = 50.0;     // PCB width (X)
pcb_depth           = 70.0;     // PCB depth (Y) — long dimension
pcb_thickness       = 1.6;      // PCB board thickness (standard FR4)
pcb_component_height= 12.0;    // Max height of tallest component on top side
pcb_bottom_clearance= 2.0;     // Clearance below PCB for solder joints/traces
pcb_corner_radius   = 2.0;     // PCB corner radius (0 = square)

// PCB mounting holes (M2.5 screws)
pcb_mount_holes     = true;
mount_hole_diameter = 2.7;      // For M2.5 screws
mount_hole_inset_x  = 3.5;     // Distance from PCB edge to hole center
mount_hole_inset_y  = 3.5;
mount_standoff_h    = 3.0;     // Height of standoffs (= pcb_bottom_clearance + margin)

/* =====================================================================
 * ENCLOSURE PARAMETERS
 * ===================================================================== */

wall_thickness      = 2.5;      // Enclosure wall thickness
base_height_extra   = 2.0;      // Extra internal height below standoffs
lid_lip_height      = 3.0;      // Overlap between lid and base
lid_lip_clearance   = 0.3;      // Tolerance for lid fit

// Computed internal dimensions
int_width  = pcb_width + 2.0;   // Internal clearance around PCB
int_depth  = pcb_depth + 2.0;
int_height = pcb_bottom_clearance + pcb_thickness + pcb_component_height + 2.0;

// External dimensions
ext_width  = int_width + wall_thickness * 2;
ext_depth  = int_depth + wall_thickness * 2;
ext_height = int_height + wall_thickness + base_height_extra;
corner_r   = pcb_corner_radius + 1.0;

/* =====================================================================
 * CONNECTORS AND OPENINGS
 * ===================================================================== */

// USB-C power input (on the short edge)
usb_c_enable        = true;
usb_c_width         = 9.5;      // USB-C plug width
usb_c_height        = 3.5;      // USB-C plug height
usb_c_center_y      = 0;        // Offset from edge center (0 = centered)
usb_c_z_offset      = mount_standoff_h + pcb_thickness + 1.5; // Height from internal floor

// JST-XH 2-pin output to nebulizer cup adapter (on the opposite short edge)
jst_enable          = true;
jst_width           = 8.0;      // JST-XH 2-pin housing width
jst_height          = 6.5;      // JST-XH 2-pin housing height
jst_center_y        = 0;
jst_z_offset        = mount_standoff_h + pcb_thickness + 2.0;

// ICSP programming header (on a long edge, accessible through a small port)
icsp_enable         = true;
icsp_width          = 14.0;     // 5-pin header width
icsp_height         = 3.0;
icsp_center_x       = 0;
icsp_z_offset       = mount_standoff_h + pcb_thickness + 1.0;

/* =====================================================================
 * USER INTERFACE
 * ===================================================================== */

// Start/stop button (through the lid)
button_enable       = true;
button_diameter     = 8.0;      // Hole for button access (or button cap)
button_x            = -int_width/4;  // Position on lid
button_y            = int_depth/4;

// LED windows (through the lid)
led_enable          = true;
led_diameter        = 3.5;      // LED window diameter
led_red_x           = int_width/4;
led_red_y           = int_depth/4;
led_green_x         = int_width/4;
led_green_y         = int_depth/4 + 8.0;

/* =====================================================================
 * ADAPTER DOCK
 *
 * Dovetail slot on one end of the enclosure for mounting the cup adapter.
 * The adapter slides in from the side and locks with a friction fit.
 * ===================================================================== */

adapter_dock_enable = true;
dovetail_width      = 10.0;     // Must match adapter's dovetail_width
dovetail_height     = 4.0;      // Must match adapter's dovetail_height
dock_length         = 30.0;     // Length of dovetail channel (along enclosure)

/* =====================================================================
 * VENTILATION
 * ===================================================================== */

vent_enable         = true;
vent_slot_width     = 1.5;
vent_slot_length    = 15.0;
vent_slot_count     = 4;
vent_slot_spacing   = 4.0;

/* =====================================================================
 * VISUAL
 * ===================================================================== */

$fn = 48;

/* =====================================================================
 * ENCLOSURE BASE
 * ===================================================================== */

module rounded_box(w, d, h, r) {
    linear_extrude(height=h)
        offset(r=r)
            offset(delta=-r)
                square([w, d], center=true);
}

module enclosure_base() {
    difference() {
        union() {
            // Main box
            rounded_box(ext_width, ext_depth, ext_height, corner_r);

            // Lid lip (raised rim for lid to sit on)
            translate([0, 0, ext_height])
                difference() {
                    rounded_box(ext_width, ext_depth, lid_lip_height, corner_r);
                    translate([0, 0, -0.1])
                        rounded_box(ext_width - wall_thickness * 2 + lid_lip_clearance * 2,
                                    ext_depth - wall_thickness * 2 + lid_lip_clearance * 2,
                                    lid_lip_height + 0.2, corner_r - wall_thickness + 0.5);
                }

            // Adapter dock rail (external)
            if (adapter_dock_enable)
                adapter_dock();
        }

        // Hollow out interior
        translate([0, 0, wall_thickness])
            rounded_box(int_width, int_depth, int_height + lid_lip_height + 1, corner_r - wall_thickness + 0.5);

        // USB-C port
        if (usb_c_enable)
            translate([0, -ext_depth/2 - 0.1, wall_thickness + usb_c_z_offset])
                usb_c_cutout();

        // JST output port
        if (jst_enable)
            translate([0, ext_depth/2 - wall_thickness - 0.1, wall_thickness + jst_z_offset])
                jst_cutout();

        // ICSP port
        if (icsp_enable)
            translate([-ext_width/2 - 0.1, icsp_center_x, wall_thickness + icsp_z_offset])
                icsp_cutout();

        // Ventilation slots on bottom
        if (vent_enable)
            vent_slots();
    }

    // PCB mounting standoffs
    if (pcb_mount_holes)
        pcb_standoffs();
}

/* =====================================================================
 * ENCLOSURE LID
 * ===================================================================== */

module enclosure_lid() {
    lid_total_height = wall_thickness + lid_lip_height;

    // Position lid next to base for printing
    translate([ext_width + 10, 0, 0]) {
        difference() {
            union() {
                // Main lid surface
                rounded_box(ext_width, ext_depth, wall_thickness, corner_r);

                // Inner lip that fits inside the base
                translate([0, 0, wall_thickness])
                    rounded_box(ext_width - wall_thickness * 2,
                                ext_depth - wall_thickness * 2,
                                lid_lip_height, corner_r - wall_thickness);
            }

            // Button hole
            if (button_enable)
                translate([button_x, button_y, -0.1])
                    cylinder(d=button_diameter, h=wall_thickness + 0.2);

            // LED windows
            if (led_enable) {
                translate([led_red_x, led_red_y, -0.1])
                    cylinder(d=led_diameter, h=wall_thickness + 0.2);
                translate([led_green_x, led_green_y, -0.1])
                    cylinder(d=led_diameter, h=wall_thickness + 0.2);
            }

            // Ventilation slots on lid
            if (vent_enable)
                for (i = [0:vent_slot_count-1]) {
                    translate([-vent_slot_length/2,
                               -((vent_slot_count-1) * vent_slot_spacing)/2 + i * vent_slot_spacing,
                               -0.1])
                        cube([vent_slot_length, vent_slot_width, wall_thickness + 0.2]);
                }
        }

        // LED light pipes (small cylinders that channel light to the surface)
        if (led_enable) {
            // These are solid transparent inserts - print in clear filament
            // or leave holes and use hot glue as a light pipe
        }
    }
}

/* =====================================================================
 * CONNECTOR CUTOUTS
 * ===================================================================== */

module usb_c_cutout() {
    // Rounded rectangle for USB-C
    translate([0, 0, 0])
        rotate([-90, 0, 0])
            linear_extrude(height=wall_thickness + 0.2)
                offset(r=1)
                    offset(delta=-1)
                        square([usb_c_width, usb_c_height], center=true);
}

module jst_cutout() {
    // Rectangle for JST-XH connector
    rotate([-90, 0, 0])
        linear_extrude(height=wall_thickness + 0.2)
            square([jst_width, jst_height], center=true);
}

module icsp_cutout() {
    // Small rectangle for programming header access
    rotate([0, 90, 0])
        linear_extrude(height=wall_thickness + 0.2)
            square([icsp_height, icsp_width], center=true);
}

/* =====================================================================
 * PCB STANDOFFS
 * ===================================================================== */

module pcb_standoffs() {
    standoff_od = mount_hole_diameter + 3.0;
    positions = [
        [-pcb_width/2 + mount_hole_inset_x, -pcb_depth/2 + mount_hole_inset_y],
        [pcb_width/2 - mount_hole_inset_x,  -pcb_depth/2 + mount_hole_inset_y],
        [-pcb_width/2 + mount_hole_inset_x, pcb_depth/2 - mount_hole_inset_y],
        [pcb_width/2 - mount_hole_inset_x,  pcb_depth/2 - mount_hole_inset_y]
    ];

    for (pos = positions) {
        translate([pos[0], pos[1], wall_thickness]) {
            difference() {
                cylinder(d=standoff_od, h=mount_standoff_h);
                translate([0, 0, -0.1])
                    cylinder(d=mount_hole_diameter, h=mount_standoff_h + 0.2);
            }
        }
    }
}

/* =====================================================================
 * VENTILATION SLOTS
 * ===================================================================== */

module vent_slots() {
    for (i = [0:vent_slot_count-1]) {
        translate([-vent_slot_length/2,
                   -((vent_slot_count-1) * vent_slot_spacing)/2 + i * vent_slot_spacing,
                   -0.1])
            cube([vent_slot_length, vent_slot_width, wall_thickness + 0.2]);
    }
}

/* =====================================================================
 * ADAPTER DOCK — Dovetail slot on enclosure for cup adapter
 * ===================================================================== */

module adapter_dock() {
    // The dock is a raised platform on one end with a dovetail channel
    dock_width = dovetail_width + wall_thickness * 2 + 4;
    dock_depth = dock_length;

    translate([0, ext_depth/2 + dock_depth/2, 0]) {
        difference() {
            // Dock platform
            rounded_box(dock_width, dock_depth, wall_thickness + dovetail_height + 2, 2);

            // Dovetail channel (the adapter slides into this)
            translate([0, 0, wall_thickness + 1]) {
                // Main channel
                cube([dovetail_width + 0.4, dock_depth + 2, dovetail_height + 0.2], center=true);

                // Entry opening on the side
                translate([0, dock_depth/2, 0])
                    cube([dovetail_width + 2, 4, dovetail_height + 2], center=true);
            }
        }
    }
}

/* =====================================================================
 * RENDER
 * ===================================================================== */

// Base
enclosure_base();

// Lid (positioned next to base for printing)
enclosure_lid();

/* =====================================================================
 * NOTES
 *
 * PRINTING:
 *   - Print base upright (open side up)
 *   - Print lid upside down (outer surface on build plate)
 *   - PETG recommended for nursery environment (chemical resistant)
 *   - 0.2mm layer height, 30-50% infill
 *
 * ASSEMBLY:
 *   1. Insert PCB onto standoffs, secure with M2.5 screws
 *   2. Route USB-C cable through port
 *   3. Connect JST cable to cup adapter
 *   4. Snap lid on
 *   5. Slide cup adapter onto dovetail dock
 *
 * SEALING:
 *   For nursery use, add a thin bead of silicone around the lid
 *   perimeter (not glue — you want it removable for maintenance).
 *   This keeps saline mist out.
 *
 * LABELING:
 *   Use a label maker or emboss text during printing:
 *   - "POWER" near USB-C port
 *   - "CUP" near JST port / adapter dock
 *   - "START/STOP" near button
 *   - Red dot by red LED window, green dot by green LED window
 * ===================================================================== */
