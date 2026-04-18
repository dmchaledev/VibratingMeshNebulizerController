/*
 * controller_enclosure.scad — BASE
 *
 * v3.1 base of the vibrating mesh nebulizer controller enclosure.
 * Renders ONLY the base box (with PCB cavity, LiPo + TP4056 battery
 * bay, connector cutouts, standoffs and vents).
 *
 * The matching lid lives in controller_enclosure_lid.scad. Shared
 * dimensions are in enclosure_config.scad — edit that file once and
 * both parts stay in sync.
 *
 * USAGE:
 *   1. (Optional) adjust parameters in enclosure_config.scad
 *   2. Preview (F5), Render (F6), Export STL for the BASE
 *   3. Open controller_enclosure_lid.scad in OpenSCAD and do the same
 *   4. Print base upright (open side up), PETG, 0.2mm, 30-50% infill
 *
 * License: MIT
 */

include <enclosure_config.scad>;

/* =====================================================================
 * ENCLOSURE BASE
 * ===================================================================== */

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
                                    lid_lip_height + 0.2,
                                    max(0.5, corner_r - wall_thickness + 0.5));
                }
        }

        // === Hollow out PCB cavity ===
        translate([pcb_offset_x, 0, wall_thickness])
            rounded_box(int_pcb_width, int_pcb_depth,
                        int_height + lid_lip_height + 1,
                        max(0.5, corner_r - wall_thickness));

        // === Hollow out battery + TP4056 bay ===
        if (battery_enable)
            translate([bat_offset_x, 0, wall_thickness])
                rounded_box(int_bat_width, int_bat_depth,
                            int_bat_height + lid_lip_height + 1,
                            max(0.5, corner_r - wall_thickness));

        // === Wire slot between battery bay and PCB cavity ===
        // Lets the TP4056 BAT+/BAT- output wires reach the PCB power rail
        // through a 5x3 mm slot just above the bay floor.
        if (battery_enable) {
            slot_x = pcb_offset_x + int_pcb_width/2 - 0.1;
            translate([slot_x, -2.5, wall_thickness + 1])
                cube([battery_wall + 0.2, 5.0, 3.0]);
        }

        // === Connector cutouts ===

        // TP4056 USB-C charging aperture on the BATTERY BAY front wall.
        // z_usbc is the center of the USB-C socket, which sits just above
        // the internal shelf that the TP4056 rests on.
        if (usb_c_enable && battery_enable) {
            z_usbc = wall_thickness + lipo_h + tp4056_shelf_t + tp4056_h/2;
            translate([bat_offset_x, -ext_depth/2 - 0.1, z_usbc])
                usb_c_cutout();
        }

        // Cable exit (rear short edge) — for the connector plug pigtail
        if (cable_enable)
            translate([pcb_offset_x, ext_depth/2 - wall_thickness/2,
                       wall_thickness + cable_z_offset])
                rotate([-90, 0, 0])
                    cylinder(d=cable_hole_diameter, h=wall_thickness + 1);

        // ICSP port (long edge, PCB side). Y=0 puts it at the PCB long-edge
        // midpoint, which is where the 5-pin programming header lives on the
        // JLCPCB turnkey board.
        if (icsp_enable)
            translate([-ext_width/2 - 0.1,
                       0,
                       wall_thickness + icsp_z_offset])
                icsp_cutout();

        // LCD I2C wire slot — small notch in the top lip so the LCD
        // ribbon can pass from the PCB cavity into the lid-mounted LCD
        // without pinching when the lid closes.
        if (lcd_enable)
            translate([pcb_offset_x + int_pcb_width/4 - lcd_wire_slot_w/2,
                       -ext_depth/2 + wall_thickness - 0.1,
                       ext_height - lcd_wire_slot_h])
                cube([lcd_wire_slot_w, wall_thickness + 0.2, lcd_wire_slot_h + lid_lip_height + 1]);

        // Ventilation slots on bottom
        if (vent_enable)
            vent_slots();
    }

    // PCB mounting standoffs
    if (pcb_mount_holes)
        pcb_standoffs();

    // Battery bay retaining ribs (LiPo)
    if (battery_enable)
        battery_ribs();

    // TP4056 internal shelf — a thin floor stuck to the bay walls at
    // z = lipo top, so the charging module sits above the pouch cell
    // and its USB-C socket aligns with the aperture in the front wall.
    if (battery_enable && tp4056_enable)
        tp4056_shelf();
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
    /* Sink each standoff base 0.05 mm into the floor so CGAL fuses them
     * to the enclosure body in the union — without the overlap each
     * standoff renders as its own disconnected volume. */
    overlap = 0.05;
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
        translate([pos[0], pos[1], wall_thickness - overlap]) {
            difference() {
                cylinder(d=standoff_od, h=mount_standoff_h + overlap);
                translate([0, 0, -0.1])
                    cylinder(d=mount_hole_diameter, h=mount_standoff_h + overlap + 0.2);
            }
        }
    }
}

/* =====================================================================
 * LIPO RETAINING RIBS
 *
 * A pair of soft ribs cradles the pouch cell so it doesn't slide
 * around during handling. Pouch cells are fragile — make sure the
 * ribs are no taller than 2 mm and have a rounded top (OpenSCAD
 * $fn=48 + small cylinder at the tip if you want to refine further).
 * ===================================================================== */

module battery_ribs() {
    rib_h = 2.0;
    rib_w = 1.5;
    overlap = 0.05;     /* Sink into the floor so CGAL fuses the ribs */

    for (side = [-1, 1]) {
        translate([bat_offset_x + side * (lipo_w/2),
                   -lipo_d/4,
                   wall_thickness - overlap])
            cube([rib_w, lipo_d/2, rib_h + overlap]);
    }
}

/* =====================================================================
 * TP4056 SHELF
 *
 * A thin floor spanning the battery bay at z = lipo top. Holds the
 * TP4056 charging module above the pouch cell. Has a cutout through
 * which the battery wires pass to the module's B+/B- pads.
 * ===================================================================== */

module tp4056_shelf() {
    z_shelf = wall_thickness + lipo_h + 0.5;

    difference() {
        // Solid slab covering the bay footprint
        translate([bat_offset_x, 0, z_shelf])
            linear_extrude(height=tp4056_shelf_t)
                square([int_bat_width - 0.5, int_bat_depth - 0.5], center=true);

        // Wire pass-through hole toward the rear of the bay
        translate([bat_offset_x, int_bat_depth/4, z_shelf - 0.1])
            cylinder(d=5.0, h=tp4056_shelf_t + 0.2);
    }

    // Small locating ribs around the TP4056 PCB footprint so it
    // doesn't float around on top of the shelf. Sink the rib bases
    // 0.05 mm into the shelf so CGAL fuses them in the union.
    overlap = 0.05;
    for (side = [-1, 1]) {
        translate([bat_offset_x + side * (tp4056_w/2),
                   -tp4056_d/4,
                   z_shelf + tp4056_shelf_t - overlap])
            cube([1.2, tp4056_d/2, 2.0 + overlap]);
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

enclosure_base();

/* =====================================================================
 * DIMENSION SUMMARY (reference values with defaults)
 *
 *   PCB cavity:        52.0 x 72.0 x 23.6 mm (internal)
 *   Battery bay:       37.6 x 55.6 x 22.8 mm (internal)
 *     - LiPo (1S 2000mAh 103450): 34 x 52 x 10 mm on floor
 *     - TP4056 shelf at z ~ 13.5 mm
 *     - TP4056 module with USB-C: ~20 x 25 x 6 mm on shelf
 *   Overall external:  ~97.0 x 77.0 x 28.1 mm (base only)
 *                      + 2.5 mm lid
 *
 *   PCB component clearance raised from 12 to 18 mm in v3.1 to give
 *   the 16x2 LCD/OLED backpack room to hang down from the lid.
 *
 * PRINTING:
 *   - Print base upright (open side up)
 *   - Print lid (from controller_enclosure_lid.scad) upside down
 *   - PETG recommended for nursery environment
 *   - 0.2 mm layer height, 30-50% infill
 *
 * ASSEMBLY:
 *   1. Insert PCB onto standoffs, secure with 4x M2.5x6 screws
 *   2. Drop LiPo pouch cell into battery bay (cells up / tab wires out)
 *   3. Route battery JST through the shelf wire hole
 *   4. Seat TP4056 module on the shelf with its USB-C facing the aperture
 *   5. Connect TP4056 BAT+/BAT- to the PCB BAT IN header
 *   6. Mount the LCD/OLED onto the lid standoffs with M3 screws
 *   7. Plug the LCD I2C ribbon into the PCB LCD header (VCC/GND/SDA/SCL)
 *   8. Route the connector-plug cable through the rear cable gland
 *   9. Close the lid
 *
 * SEALING:
 *   For nursery use, add a thin bead of silicone around the lid
 *   perimeter (not glue — you want it removable for maintenance).
 * ===================================================================== */
