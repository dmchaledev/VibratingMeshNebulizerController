/*
 * controller_enclosure.scad
 *
 * 3D-printable enclosure for the assembled nebulizer controller PCB
 * with integrated battery compartment for 3x AAA cells.
 *
 * Designed for a JLCPCB-assembled PCB (see docs/JLCPCB_ORDERING_GUIDE.md).
 *
 * USAGE:
 *   1. Measure your assembled PCB and update dimensions below
 *   2. Preview (F5), Render (F6), Export STL
 *   3. Print BOTH the base and lid
 *   4. Print in PETG for best durability and chemical resistance
 *
 * License: MIT
 */

/* =====================================================================
 * PCB DIMENSIONS
 *
 * Measure your assembled PCB (or use the reference design dimensions).
 * The JLCPCB turnkey board is a 2-layer ~50x70mm FR4 PCB.
 * ===================================================================== */

pcb_width           = 50.0;     // PCB width (X) — short dimension
pcb_depth           = 70.0;     // PCB depth (Y) — long dimension
pcb_thickness       = 1.6;      // PCB board thickness (standard FR4)
pcb_component_height= 12.0;     // Max height of tallest component on top side
                                 // (JST headers ~8mm, tactile switch ~5mm,
                                 //  boost module plugs in externally via JST)
pcb_bottom_clearance= 2.0;      // Clearance below PCB for solder joints/traces
pcb_corner_radius   = 2.0;      // PCB corner radius (0 = square)

// PCB mounting holes (M2.5 screws)
pcb_mount_holes     = true;
mount_hole_diameter = 2.7;      // For M2.5 screws (2.5mm + clearance)
mount_hole_inset_x  = 3.5;      // Distance from PCB edge to hole center
mount_hole_inset_y  = 3.5;
mount_standoff_h    = 3.0;      // Height of standoffs

/* =====================================================================
 * BATTERY COMPARTMENT
 *
 * Space for 3x AAA batteries (side-by-side configuration).
 * AAA cell: 44.5mm long x 10.5mm diameter
 * A 3-cell AAA holder is approximately 52mm x 35mm x 12mm.
 * The battery compartment sits alongside the PCB on the long edge.
 * ===================================================================== */

battery_enable      = true;
battery_holder_w    = 36.0;     // Battery holder width (3 cells side-by-side + tolerance)
battery_holder_d    = 53.0;     // Battery holder depth (AAA length + spring + tolerance)
battery_holder_h    = 12.0;     // Battery holder height (cell diameter + tolerance)
battery_wall        = 1.5;      // Thin wall between battery compartment and PCB cavity
battery_clearance   = 1.0;      // Extra clearance around holder for easy insertion

/* =====================================================================
 * ENCLOSURE PARAMETERS
 * ===================================================================== */

wall_thickness      = 2.5;      // Enclosure wall thickness
base_height_extra   = 2.0;      // Extra internal height below standoffs
lid_lip_height      = 3.0;      // Overlap between lid and base
lid_lip_clearance   = 0.3;      // Tolerance for lid fit

// Computed internal dimensions
// PCB cavity
int_pcb_width  = pcb_width + 2.0;    // Internal clearance around PCB
int_pcb_depth  = pcb_depth + 2.0;
int_pcb_height = pcb_bottom_clearance + pcb_thickness + pcb_component_height + 2.0;

// Battery cavity (alongside PCB on the X axis)
int_bat_width  = battery_enable ? battery_holder_w + battery_clearance * 2 : 0;
int_bat_depth  = battery_holder_d + battery_clearance * 2;
int_bat_height = battery_holder_h + 2.0;

// Overall internal dimensions
int_width  = int_pcb_width + (battery_enable ? battery_wall + int_bat_width : 0);
int_depth  = max(int_pcb_depth, battery_enable ? int_bat_depth : 0);
int_height = max(int_pcb_height, battery_enable ? int_bat_height : 0);

// External dimensions
ext_width  = int_width + wall_thickness * 2;
ext_depth  = int_depth + wall_thickness * 2;
ext_height = int_height + wall_thickness + base_height_extra;
corner_r   = pcb_corner_radius + 1.0;

// PCB offset from enclosure center (shifted left to make room for battery)
pcb_offset_x = battery_enable ? -(int_bat_width + battery_wall) / 2 : 0;

// Battery compartment offset from enclosure center (shifted right)
bat_offset_x = battery_enable ? (int_pcb_width + battery_wall) / 2 : 0;

/* =====================================================================
 * CONNECTORS AND OPENINGS
 * ===================================================================== */

// USB-C power input (on the short edge, PCB side)
usb_c_enable        = true;
usb_c_width         = 9.5;      // USB-C plug width
usb_c_height        = 3.5;      // USB-C plug height
usb_c_center_y      = 0;        // Offset from PCB center (0 = centered on PCB)
usb_c_z_offset      = mount_standoff_h + pcb_thickness + 1.5;

// Cable gland / strain relief for connector cable (on the opposite short edge)
cable_enable        = true;
cable_hole_diameter = 6.0;       // For PG7 cable gland or strain relief grommet
cable_center_y      = 0;
cable_z_offset      = mount_standoff_h + pcb_thickness + 3.0;

// ICSP programming header (on a long edge, accessible through a small port)
icsp_enable         = true;
icsp_width          = 14.0;     // 5-pin header width
icsp_height         = 3.0;
icsp_center_x       = 0;
icsp_z_offset       = mount_standoff_h + pcb_thickness + 1.0;

// Battery compartment access (slot on the side for battery holder wires)
battery_wire_slot_w = 4.0;      // Width of wire slot between battery and PCB cavities
battery_wire_slot_h = 3.0;

/* =====================================================================
 * USER INTERFACE
 * ===================================================================== */

// Start/stop button (through the lid)
button_enable       = true;
button_diameter     = 8.0;
button_x            = pcb_offset_x - int_pcb_width/4;
button_y            = int_depth/4;

// LED windows (through the lid)
led_enable          = true;
led_diameter        = 3.5;
led_red_x           = pcb_offset_x + int_pcb_width/4;
led_red_y           = int_depth/4;
led_green_x         = pcb_offset_x + int_pcb_width/4;
led_green_y         = int_depth/4 + 8.0;

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
        }

        // === Hollow out PCB cavity ===
        translate([pcb_offset_x, 0, wall_thickness])
            rounded_box(int_pcb_width, int_pcb_depth,
                        int_height + lid_lip_height + 1,
                        max(0.5, corner_r - wall_thickness));

        // === Hollow out battery cavity ===
        if (battery_enable)
            translate([bat_offset_x, 0, wall_thickness])
                rounded_box(int_bat_width, int_bat_depth,
                            int_bat_height + 1,
                            max(0.5, corner_r - wall_thickness));

        // === Wire slot between battery and PCB cavities ===
        if (battery_enable) {
            slot_x = pcb_offset_x + int_pcb_width/2 - 0.1;
            translate([slot_x, -battery_wire_slot_w/2, wall_thickness + 1])
                cube([battery_wall + 0.2, battery_wire_slot_w, battery_wire_slot_h]);
        }

        // === Connector cutouts ===

        // USB-C port (front short edge)
        if (usb_c_enable)
            translate([pcb_offset_x + usb_c_center_y, -ext_depth/2 - 0.1,
                       wall_thickness + usb_c_z_offset])
                usb_c_cutout();

        // Cable exit (rear short edge) — for connector plug cable
        if (cable_enable)
            translate([pcb_offset_x + cable_center_y, ext_depth/2 - wall_thickness/2,
                       wall_thickness + cable_z_offset])
                rotate([-90, 0, 0])
                    cylinder(d=cable_hole_diameter, h=wall_thickness + 1);

        // ICSP port (long edge, PCB side)
        if (icsp_enable)
            translate([-ext_width/2 - 0.1,
                       pcb_offset_x + icsp_center_x,
                       wall_thickness + icsp_z_offset])
                icsp_cutout();

        // Ventilation slots on bottom
        if (vent_enable)
            vent_slots();
    }

    // PCB mounting standoffs
    if (pcb_mount_holes)
        pcb_standoffs();

    // Battery holder retaining ribs
    if (battery_enable)
        battery_ribs();
}

/* =====================================================================
 * ENCLOSURE LID
 * ===================================================================== */

module enclosure_lid() {
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

            // Ventilation slots on lid (over PCB area only)
            if (vent_enable)
                for (i = [0:vent_slot_count-1]) {
                    translate([pcb_offset_x - vent_slot_length/2,
                               -((vent_slot_count-1) * vent_slot_spacing)/2 + i * vent_slot_spacing,
                               -0.1])
                        cube([vent_slot_length, vent_slot_width, wall_thickness + 0.2]);
                }

            // Battery compartment label recess (optional: emboss "BATT" on lid)
            if (battery_enable)
                translate([bat_offset_x, 0, wall_thickness - 0.4])
                    linear_extrude(height=0.5)
                        text("BATT", size=6, halign="center", valign="center");
        }
    }
}

/* =====================================================================
 * CONNECTOR CUTOUTS
 * ===================================================================== */

module usb_c_cutout() {
    // Rounded rectangle for USB-C
    rotate([-90, 0, 0])
        linear_extrude(height=wall_thickness + 0.2)
            offset(r=1)
                offset(delta=-1)
                    square([usb_c_width, usb_c_height], center=true);
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
        [pcb_offset_x - pcb_width/2 + mount_hole_inset_x,
         -pcb_depth/2 + mount_hole_inset_y],
        [pcb_offset_x + pcb_width/2 - mount_hole_inset_x,
         -pcb_depth/2 + mount_hole_inset_y],
        [pcb_offset_x - pcb_width/2 + mount_hole_inset_x,
         pcb_depth/2 - mount_hole_inset_y],
        [pcb_offset_x + pcb_width/2 - mount_hole_inset_x,
         pcb_depth/2 - mount_hole_inset_y]
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
 * BATTERY HOLDER RIBS
 *
 * Small ribs on the floor and walls of the battery cavity to hold
 * a standard 3xAAA battery holder in place.
 * ===================================================================== */

module battery_ribs() {
    rib_h = 2.0;       // Rib height above cavity floor
    rib_w = 1.5;       // Rib width

    // Two ribs along the long axis to cradle the battery holder
    for (side = [-1, 1]) {
        translate([bat_offset_x + side * (battery_holder_w/2 + battery_clearance/2),
                   -battery_holder_d/4,
                   wall_thickness]) {
            cube([rib_w, battery_holder_d/2, rib_h]);
        }
    }
}

/* =====================================================================
 * VENTILATION SLOTS
 * ===================================================================== */

module vent_slots() {
    for (i = [0:vent_slot_count-1]) {
        translate([pcb_offset_x - vent_slot_length/2,
                   -((vent_slot_count-1) * vent_slot_spacing)/2 + i * vent_slot_spacing,
                   -0.1])
            cube([vent_slot_length, vent_slot_width, wall_thickness + 0.2]);
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
 * DIMENSION SUMMARY (for reference)
 *
 * With default parameters:
 *
 *   PCB cavity:     52.0 x 72.0 x 19.6 mm (internal)
 *   Battery cavity: 38.0 x 55.0 x 14.0 mm (internal)
 *   Overall external: ~97.0 x 77.0 x 25.6 mm (+ wall + lid)
 *
 *   3x AAA holder:  ~36 x 53 x 12 mm (fits with 1mm clearance all around)
 *   PCB:            50 x 70 x 1.6 mm (with 1mm clearance all around)
 *   Tallest component on PCB: ~12mm (JST headers, boost module JST plug)
 *
 *   Battery holder wires route through a 4x3mm slot in the divider wall
 *   to the PCB power input.
 *
 * PRINTING:
 *   - Print base upright (open side up)
 *   - Print lid upside down (outer surface on build plate)
 *   - PETG recommended for nursery environment
 *   - 0.2mm layer height, 30-50% infill
 *
 * ASSEMBLY:
 *   1. Insert PCB onto standoffs, secure with M2.5 screws
 *   2. Route USB-C cable through port (or use batteries)
 *   3. Insert 3xAAA battery holder, route wires through slot
 *   4. Connect connector plug cable through cable gland
 *   5. Snap lid on
 *
 * SEALING:
 *   For nursery use, add a thin bead of silicone around the lid
 *   perimeter (not glue — you want it removable for maintenance).
 * ===================================================================== */
