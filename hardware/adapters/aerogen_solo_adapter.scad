/*
 * aerogen_solo_adapter.scad
 *
 * Parametric 3D-printable adapter for the Aerogen Solo nebulizer cup.
 * Provides spring-loaded pogo pin contact to the PZT leads.
 *
 * USAGE:
 *   1. Measure your Aerogen Solo cup (see README.md measurement guide)
 *   2. Enter measurements in the "USER MEASUREMENTS" section below
 *   3. Preview with F5, render with F6
 *   4. Export STL: File > Export > Export as STL
 *   5. Print in PETG (preferred) or PLA
 *
 * PRINT SETTINGS:
 *   Layer height: 0.2mm
 *   Infill: 30-50%
 *   Supports: Yes (for pogo pin channels)
 *   Orientation: Cup opening facing up
 *
 * Based on Aerogen Solo DIY Controller project.
 * License: MIT
 */

/* =====================================================================
 * USER MEASUREMENTS — Update these with YOUR cup's dimensions
 *
 * All dimensions in millimeters. Measure with calipers if possible.
 * See hardware/adapters/README.md for a detailed measurement guide.
 *
 * DEFAULT VALUES BELOW ARE ESTIMATES. They will get you close but
 * you should measure your actual cup for a precise fit.
 * ===================================================================== */

// --- Cup body dimensions ---
cup_outer_diameter  = 33.0;     // Outer diameter of cup body at widest point
cup_height          = 25.0;     // Total cup height (bottom face to top rim)
cup_lip_diameter    = 30.0;     // Diameter of any narrower lip on the bottom (0 = no lip)
cup_lip_height      = 2.0;     // Height of bottom lip/step (0 = no lip)
cup_taper_angle     = 0;       // Degrees of taper if cup isn't cylindrical (0 = straight)

// --- Contact pad dimensions ---
// The two flat pads on the bottom face of the Aerogen Solo cup
contact_spacing     = 10.0;     // Center-to-center distance between the two pads
contact_diameter    = 3.0;      // Diameter of each circular contact pad
contact_inset       = 0.0;      // How far the pad surface is recessed below the cup bottom (0 = flush)
contact_offset_x    = 0.0;      // X offset of contact pair center from cup center
contact_offset_y    = 0.0;      // Y offset of contact pair center from cup center

// --- Alignment feature ---
// If the cup has a flat edge or notch for orientation, set these:
flat_width          = 0;        // Width of flat section on cup perimeter (0 = none)
alignment_notch     = false;    // true if there's a notch rather than a flat

/* =====================================================================
 * POGO PIN SPECIFICATIONS
 *
 * Default: P75-B1 (the most common, cheapest, and readily available)
 * Only change these if you're using a different pogo pin model.
 * ===================================================================== */

pogo_body_diameter  = 1.02;     // Outer diameter of pogo pin barrel
pogo_tip_diameter   = 0.68;     // Diameter of the pointed tip
pogo_total_length   = 16.5;     // Total length of pogo pin (uncompressed)
pogo_travel         = 1.5;      // Spring travel (compression distance)
pogo_preload        = 1.0;      // How much the pin is pre-compressed when cup is seated (mm)
                                // Higher = more contact force. 0.5-1.5mm recommended.

/* =====================================================================
 * ADAPTER DESIGN PARAMETERS
 *
 * You generally don't need to change these unless you have fit issues.
 * ===================================================================== */

// --- Tolerances ---
cup_clearance       = 0.4;      // Gap between cup and cradle wall (0.3-0.5mm typical for FDM)
pogo_clearance      = 0.15;     // Gap around pogo pin barrel in its channel

// --- Adapter body ---
wall_thickness      = 2.5;      // Cradle wall thickness
base_thickness      = 8.0;      // Base thickness (must accommodate pogo pin length below contact surface)
cup_cradle_depth    = 15.0;     // How deep the cup sits in the cradle
adapter_chamfer     = 1.0;      // Chamfer on outer edges

// --- Cable channel ---
cable_channel_width = 6.0;      // Width of wire exit channel
cable_channel_height= 4.0;      // Height of wire exit channel

// --- Retention ---
use_magnets         = true;     // Set true to include magnet pockets
magnet_diameter     = 6.0;      // Diameter of retention magnets
magnet_thickness    = 2.0;      // Thickness of retention magnets
magnet_count        = 2;        // Number of magnets (evenly spaced)

// --- Dovetail mount ---
// For connecting to the controller enclosure
use_dovetail        = true;     // Include dovetail rail on bottom
dovetail_width      = 10.0;     // Width of dovetail rail
dovetail_height     = 4.0;      // Height of dovetail rail
dovetail_angle      = 60;       // Dovetail angle (degrees)

// --- Visual ---
$fn = 64;                       // Circle resolution (increase for smoother prints)

/* =====================================================================
 * COMPUTED DIMENSIONS — Do not edit below this line
 * ===================================================================== */

cradle_id = cup_outer_diameter + cup_clearance * 2;
cradle_od = cradle_id + wall_thickness * 2;
total_height = base_thickness + cup_cradle_depth;
pogo_channel_diameter = pogo_body_diameter + pogo_clearance * 2;

// Pogo pin vertical positioning:
// The tip should protrude above the base's inner surface by (pogo_preload) mm
// when the cup is seated, so the pin is pre-compressed.
pogo_channel_depth = base_thickness + contact_inset + pogo_preload;

/* =====================================================================
 * MAIN ADAPTER BODY
 * ===================================================================== */

module adapter_body() {
    difference() {
        union() {
            // Main cylindrical body
            cylinder(d=cradle_od, h=total_height);

            // Dovetail rail on bottom
            if (use_dovetail) {
                translate([0, 0, 0])
                    dovetail_rail();
            }
        }

        // Cup cradle bore (the pocket the cup sits in)
        translate([0, 0, base_thickness])
            cup_bore();

        // Pogo pin channels
        pogo_channels();

        // Wire channel from pogo pins to edge of adapter
        wire_channel();

        // Cable exit
        cable_exit();

        // Magnet pockets
        if (use_magnets)
            magnet_pockets();

        // Chamfer the top edge (entry chamfer for cup insertion)
        translate([0, 0, total_height])
            entry_chamfer();
    }
}

/* =====================================================================
 * CUP BORE — The cylindrical pocket that holds the cup
 * ===================================================================== */

module cup_bore() {
    // Main bore
    if (cup_taper_angle == 0) {
        // Straight cylinder
        cylinder(d=cradle_id, h=cup_cradle_depth + 1);
    } else {
        // Tapered bore
        cylinder(d1=cradle_id,
                 d2=cradle_id + 2 * cup_cradle_depth * tan(cup_taper_angle),
                 h=cup_cradle_depth + 1);
    }

    // Lip recess (if cup has a narrower bottom lip)
    if (cup_lip_height > 0 && cup_lip_diameter > 0) {
        lip_bore = cup_lip_diameter + cup_clearance * 2;
        translate([0, 0, -cup_lip_height])
            cylinder(d=lip_bore, h=cup_lip_height + 0.1);
    }

    // Alignment flat (if cup has one)
    if (flat_width > 0) {
        flat_offset = cradle_id/2 - (cradle_id/2 - sqrt((cradle_id/2)*(cradle_id/2) - (flat_width/2)*(flat_width/2)));
        translate([flat_offset, -flat_width/2, 0])
            cube([wall_thickness + 1, flat_width, cup_cradle_depth + 1]);
    }
}

/* =====================================================================
 * POGO PIN CHANNELS
 * ===================================================================== */

module pogo_channels() {
    for (i = [-1, 1]) {
        x = contact_offset_x + i * contact_spacing / 2;
        y = contact_offset_y;

        // Main pin channel (full depth through base)
        translate([x, y, -0.1])
            cylinder(d=pogo_channel_diameter, h=pogo_channel_depth + 0.2);

        // Wider solder cup recess at the bottom (for wire attachment)
        translate([x, y, -0.1])
            cylinder(d=pogo_channel_diameter + 1.5, h=4.1);
    }
}

/* =====================================================================
 * WIRE CHANNEL — Routes wires from pogo pin bases to cable exit
 * ===================================================================== */

module wire_channel() {
    // Channel running from the pogo pins to the edge of the adapter
    channel_y = contact_offset_y;

    // Horizontal channel at the base level
    translate([-cradle_od/2 - 1, channel_y - cable_channel_width/2, 1.5])
        cube([cradle_od/2 + 1 + contact_offset_x + contact_spacing/2 + 2,
              cable_channel_width,
              cable_channel_height]);
}

/* =====================================================================
 * CABLE EXIT — Where wires leave the adapter body
 * ===================================================================== */

module cable_exit() {
    // Rounded exit on the side of the adapter
    translate([-cradle_od/2 - 0.1, contact_offset_y, 1.5 + cable_channel_height/2])
        rotate([0, 90, 0])
            cylinder(d=cable_channel_height + 1, h=wall_thickness + 0.2);

    // Strain relief notch (zip tie slot)
    translate([-cradle_od/2 + wall_thickness, contact_offset_y - cable_channel_width/2 - 1, 0])
        cube([3, cable_channel_width + 2, 2]);
}

/* =====================================================================
 * MAGNET POCKETS — For cup retention
 * ===================================================================== */

module magnet_pockets() {
    if (magnet_count > 0) {
        for (i = [0:magnet_count-1]) {
            angle = i * 360 / magnet_count + 90;  // Start at top, space evenly
            // Avoid placing magnets where the cable exit is
            if (abs(angle - 180) > 30) {
                x = (cradle_od/2 - magnet_thickness/2 - 0.5) * cos(angle);
                y = (cradle_od/2 - magnet_thickness/2 - 0.5) * sin(angle);

                translate([x, y, base_thickness + cup_cradle_depth/2])
                    rotate([0, 0, angle])
                        rotate([0, 90, 0])
                            cylinder(d=magnet_diameter + 0.2, h=magnet_thickness + 0.1);
            }
        }
    }
}

/* =====================================================================
 * ENTRY CHAMFER — Makes it easy to drop the cup in
 * ===================================================================== */

module entry_chamfer() {
    chamfer_size = 2.0;
    difference() {
        cylinder(d=cradle_od + 0.2, h=chamfer_size);
        translate([0, 0, -0.1])
            cylinder(d1=cradle_id, d2=cradle_id + chamfer_size * 2, h=chamfer_size + 0.2);
    }
}

/* =====================================================================
 * DOVETAIL RAIL — For mounting to enclosure
 * ===================================================================== */

module dovetail_rail() {
    // Trapezoidal rail on the bottom of the adapter
    rail_length = cradle_od * 0.8;
    top_width = dovetail_width;
    bottom_width = dovetail_width - 2 * dovetail_height * tan(90 - dovetail_angle);

    translate([0, 0, -dovetail_height])
        linear_extrude(height=dovetail_height)
            polygon([
                [-rail_length/2, -bottom_width/2],
                [rail_length/2, -bottom_width/2],
                [rail_length/2, bottom_width/2],
                [-rail_length/2, bottom_width/2]
            ]);

    // Tapered version for proper dovetail
    translate([0, 0, -dovetail_height])
        linear_extrude(height=dovetail_height)
            hull() {
                translate([-rail_length/2, 0])
                    square([rail_length, bottom_width], center=true);
            }
}

/* =====================================================================
 * CONTACT ALIGNMENT INDICATOR
 * Subtle marks on the adapter body showing where the contacts are
 * ===================================================================== */

module contact_indicators() {
    for (i = [-1, 1]) {
        x = contact_offset_x + i * contact_spacing / 2;
        angle = atan2(contact_offset_y, x);

        // Small notch on the outer wall at each contact position
        translate([0, 0, base_thickness + cup_cradle_depth * 0.7])
            rotate([0, 0, angle])
                translate([cradle_od/2 - 0.3, -0.5, 0])
                    cube([0.8, 1.0, cup_cradle_depth * 0.3]);
    }
}

/* =====================================================================
 * RENDER
 * ===================================================================== */

// Main adapter
difference() {
    adapter_body();
    contact_indicators();
}

// --- For visualization only: show pogo pins in place ---
// Uncomment the block below to see the pogo pins in the preview

/*
%color("gold") {
    for (i = [-1, 1]) {
        x = contact_offset_x + i * contact_spacing / 2;
        y = contact_offset_y;
        translate([x, y, base_thickness - pogo_total_length + pogo_preload + contact_inset])
            cylinder(d=pogo_body_diameter, h=pogo_total_length);
    }
}
*/

// --- For visualization only: show the cup in place ---
// Uncomment the block below to see the cup ghost

/*
%color("lightblue", 0.3) {
    translate([0, 0, base_thickness])
        cylinder(d=cup_outer_diameter, h=cup_height);
}
*/

/* =====================================================================
 * REVISION NOTES
 *
 * When you print and test-fit, you may need to adjust:
 * - cup_clearance: Increase if cup doesn't fit; decrease if too loose
 * - pogo_preload: Increase if contact is intermittent; decrease if cup won't seat
 * - cup_cradle_depth: Increase for more secure hold; decrease if cup is hard to remove
 *
 * After a successful fit, save your measurements! They're specific to your
 * cup batch and printer calibration.
 * ===================================================================== */
