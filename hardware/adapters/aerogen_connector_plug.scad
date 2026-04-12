/*
 * aerogen_connector_plug.scad
 *
 * 3D-printable connector plug that mates with the Aerogen Solo
 * nebulizer cup's 2-pin electrical connector.
 *
 * The Aerogen Solo cup has two long connector pins recessed inside
 * a small rectangular housing (7.25mm × 5.25mm). The pins are spaced
 * 3.25mm apart (center-to-center), caliper-verified.
 *
 * This plug inserts into that housing and makes electrical contact
 * with the pins via spring-loaded pogo pin sockets. A flexible cable
 * connects the plug to the controller enclosure via a JST connector.
 *
 * Connector slot dimensions verified with calipers:
 *   7.25mm × 5.25mm opening, 7.25mm deep, 3.25mm pin spacing,
 *   1.1mm pin diameter, 8.5mm pin protrusion, sharp-edged slot.
 * Print a test fit before committing to final assembly.
 *
 * USAGE:
 *   1. Measure your Aerogen Solo cup connector with calipers
 *   2. Update the measurements below
 *   3. Preview (F5), Render (F6), Export STL
 *   4. Print in PETG or SLA resin (resin gives better pin channel precision)
 *   5. Install pogo pin sockets, solder cable, crimp JST plug
 *
 * PRINT SETTINGS:
 *   Layer height: 0.12-0.2mm (finer = better pin channel fit)
 *   Infill: 50%+
 *   Supports: Yes (for socket channels)
 *   Material: PETG or SLA resin (preferred)
 *
 * License: MIT
 */

/* =====================================================================
 * CONNECTOR MEASUREMENTS — Caliper-verified on Aerogen Solo cup
 *
 * All dimensions in millimeters.
 * Measured 2026-04-12 with calipers on a physical Aerogen Solo cup.
 *
 * The connector housing on the Aerogen Solo cup is a small rectangular
 * slot on the bottom of the cup containing two protruding pins.
 * ===================================================================== */

// --- Connector housing (the slot on the cup) ---
housing_width       = 7.25;     // Caliper-verified — wider axis of slot opening (along pin row)
housing_depth       = 5.25;     // Caliper-verified — narrower axis of slot opening
housing_height      = 7.25;     // Caliper-verified — depth of the slot recess
housing_corner_r    = 0;        // Caliper-verified — housing slot has sharp edges (0 = sharp)

// --- Pin dimensions ---
pin_count           = 2;        // Number of pins in the connector
pin_spacing         = 3.25;     // Caliper-verified — center-to-center spacing
pin_diameter        = 1.1;      // Caliper-verified — pin diameter
pin_length          = 8.5;      // Caliper-verified — pin protrusion from housing floor

// --- Pin layout ---
// Pins are assumed to be in a line along the width axis, centered in the housing
pin_offset_x        = 0.0;      // Offset of pin pair center from housing center (X)
pin_offset_y        = 0.0;      // Offset of pin pair center from housing center (Y)

/* =====================================================================
 * POGO PIN SOCKET SPECIFICATIONS
 *
 * The plug uses pogo pin sockets (receptacles) that receive the cup's
 * protruding pins. When the plug is pressed onto the cup connector,
 * the cup's pins push into the pogo sockets, making spring-loaded
 * electrical contact.
 *
 * Default: P75-B1 or P75-E2 pogo pin receptacles
 * ===================================================================== */

pogo_socket_od      = 1.50;     // Outer diameter of pogo socket barrel
pogo_socket_id      = 1.10;     // Inner bore that receives the cup pin
pogo_socket_length  = 16.5;     // Total length of pogo socket
pogo_preload        = 0.5;      // Spring pre-compression when cup pins are inserted (mm)
pogo_clearance      = 0.15;     // Print clearance around socket barrel

/* =====================================================================
 * PLUG DESIGN PARAMETERS
 * ===================================================================== */

// --- Plug body ---
plug_clearance      = 0.3;      // Gap between plug and housing walls (for easy insertion)
plug_wall           = 2.0;      // Wall thickness around the plug body
plug_base_thickness = 10.0;     // Base thickness below socket channels (houses sockets + wires)
plug_insertion_depth= 5.0;      // How far the plug inserts into the cup housing

// Computed plug dimensions
plug_inner_w = housing_width - plug_clearance * 2;  // Plug face that enters the housing
plug_inner_d = housing_depth - plug_clearance * 2;
plug_outer_w = housing_width + plug_wall * 2;       // Outer grip/body of the plug
plug_outer_d = housing_depth + plug_wall * 2;
plug_total_h = plug_base_thickness + plug_insertion_depth;

// --- Cable exit ---
cable_channel_w     = 5.0;      // Width of cable exit channel
cable_channel_h     = 3.5;      // Height of cable exit channel
cable_exit_side     = "back";   // Which side the cable exits: "back" or "bottom"

// --- Strain relief ---
strain_relief_enable = true;
strain_relief_slot_w = 3.0;     // Width of zip-tie slot for strain relief
strain_relief_slot_d = 2.0;     // Depth of zip-tie slot

// --- Grip features ---
grip_ridges         = true;     // Add grip ridges on the sides for easy insertion/removal
grip_ridge_count    = 4;
grip_ridge_depth    = 0.5;

// --- Visual ---
$fn = 64;

/* =====================================================================
 * COMPUTED DIMENSIONS
 * ===================================================================== */

socket_channel_d = pogo_socket_od + pogo_clearance * 2;

/* =====================================================================
 * PLUG BODY
 * ===================================================================== */

module plug_body() {
    difference() {
        union() {
            // Outer grip body (wider part that stays outside the housing)
            translate([0, 0, 0])
                rounded_rect(plug_outer_w, plug_outer_d, plug_base_thickness,
                             housing_corner_r + plug_wall);

            // Insertion tongue (narrower part that enters the housing)
            translate([0, 0, plug_base_thickness])
                rounded_rect(plug_inner_w, plug_inner_d, plug_insertion_depth,
                             max(0.5, housing_corner_r - 0.5));

            // Entry chamfer (taper between outer body and insertion tongue)
            translate([0, 0, plug_base_thickness - 1.0])
                hull() {
                    rounded_rect(plug_outer_w, plug_outer_d, 0.1,
                                 housing_corner_r + plug_wall);
                    translate([0, 0, 1.0])
                        rounded_rect(plug_inner_w, plug_inner_d, 0.1,
                                     max(0.5, housing_corner_r - 0.5));
                }
        }

        // Pogo socket channels (vertical holes for the pogo sockets)
        socket_channels();

        // Wire routing channels (from socket bottoms to cable exit)
        wire_channels();

        // Cable exit
        cable_exit();

        // Grip ridges (subtractive — grooves in the sides)
        if (grip_ridges)
            grip_grooves();

        // Strain relief slot
        if (strain_relief_enable)
            strain_relief();
    }
}

/* =====================================================================
 * ROUNDED RECTANGLE HELPER
 * ===================================================================== */

module rounded_rect(w, d, h, r) {
    r_safe = min(r, min(w, d) / 2 - 0.01);
    linear_extrude(height=h)
        offset(r=r_safe)
            offset(delta=-r_safe)
                square([w, d], center=true);
}

/* =====================================================================
 * POGO SOCKET CHANNELS
 *
 * Vertical channels that hold the pogo sockets. The cup's pins push
 * down into these sockets from above (the insertion face).
 * ===================================================================== */

module socket_channels() {
    for (i = [-1, 1]) {
        x = pin_offset_x + i * pin_spacing / 2;
        y = pin_offset_y;

        // Main socket channel (full depth)
        translate([x, y, -0.1])
            cylinder(d=socket_channel_d, h=plug_total_h + 0.2);

        // Wider recess at the bottom for solder cup / wire attachment
        translate([x, y, -0.1])
            cylinder(d=socket_channel_d + 2.0, h=4.1);

        // Pin entry chamfer at the top (guides the cup pin into the socket)
        translate([x, y, plug_total_h - 0.5])
            cylinder(d1=socket_channel_d, d2=socket_channel_d + 1.0, h=0.6);
    }
}

/* =====================================================================
 * WIRE CHANNELS
 *
 * Routes wires from pogo socket solder cups to the cable exit.
 * ===================================================================== */

module wire_channels() {
    // Horizontal channel at the base connecting both sockets to the cable exit side
    channel_z = 2.0;   // Height of channel center above plug bottom

    // Channel from sockets toward cable exit
    translate([-pin_spacing/2 - socket_channel_d,
               pin_offset_y - cable_channel_w/2,
               channel_z])
        cube([pin_spacing + socket_channel_d * 2,
              cable_channel_w,
              cable_channel_h]);

    // Channel from pin area to the cable exit edge
    if (cable_exit_side == "back") {
        translate([pin_offset_x - cable_channel_w/2,
                   pin_offset_y,
                   channel_z])
            cube([cable_channel_w,
                  plug_outer_d/2 + 1,
                  cable_channel_h]);
    }
}

/* =====================================================================
 * CABLE EXIT
 * ===================================================================== */

module cable_exit() {
    if (cable_exit_side == "back") {
        // Cable exits from the back face of the plug body
        translate([pin_offset_x, plug_outer_d/2 - 0.1, 2.0 + cable_channel_h/2])
            rotate([-90, 0, 0])
                cylinder(d=cable_channel_h + 1, h=plug_wall + 0.2);
    } else {
        // Cable exits from the bottom face
        translate([pin_offset_x, pin_offset_y, -0.1])
            cylinder(d=cable_channel_h + 1, h=2.0);
    }
}

/* =====================================================================
 * GRIP GROOVES
 * ===================================================================== */

module grip_grooves() {
    groove_spacing = plug_base_thickness / (grip_ridge_count + 1);
    for (side = [0, 180]) {
        for (i = [1:grip_ridge_count]) {
            rotate([0, 0, side])
                translate([plug_outer_w/2 - grip_ridge_depth, -plug_outer_d/2 - 0.1,
                           i * groove_spacing - 0.3])
                    cube([grip_ridge_depth + 0.1, plug_outer_d + 0.2, 0.6]);
        }
    }
}

/* =====================================================================
 * STRAIN RELIEF
 * ===================================================================== */

module strain_relief() {
    if (cable_exit_side == "back") {
        // Zip-tie slot behind the cable exit
        translate([pin_offset_x - strain_relief_slot_w * 1.5,
                   plug_outer_d/2 - strain_relief_slot_d,
                   0])
            cube([strain_relief_slot_w * 3, strain_relief_slot_d + 0.1, strain_relief_slot_w]);
    }
}

/* =====================================================================
 * RENDER
 * ===================================================================== */

// Main plug
plug_body();

// --- Visualization: show cup pins (uncomment to preview) ---
/*
%color("gold") {
    for (i = [-1, 1]) {
        x = pin_offset_x + i * pin_spacing / 2;
        y = pin_offset_y;
        // Cup pins coming down from above into the sockets
        translate([x, y, plug_total_h - pin_length])
            cylinder(d=pin_diameter, h=pin_length + 2);
    }
}
*/

/* =====================================================================
 * ASSEMBLY INSTRUCTIONS
 *
 * 1. Print the plug body
 *
 * 2. Insert pogo pin sockets:
 *    - Push one P75-B1 (or P75-E2) pogo socket into each channel
 *      from the bottom of the plug
 *    - The socket's receiving end (open bore) should face UP
 *      toward the insertion face
 *    - Optionally secure with a tiny drop of CA glue on the barrel
 *      (NOT on the spring mechanism)
 *
 * 3. Solder cable:
 *    - Cut two lengths of flexible stranded wire (24-28 AWG), ~30-50cm
 *    - Solder one wire to each pogo socket's solder cup
 *    - Route wires through the cable channel
 *    - No polarity requirement — PZT is an AC device
 *
 * 4. Terminate cable:
 *    - Crimp or solder wires to a JST-XH 2-pin plug
 *    - This plugs into the JST-XH header on the controller PCB
 *    - Thread the cable through the enclosure cable gland before
 *      crimping the JST plug
 *
 * 5. Strain relief:
 *    - Loop a small zip tie through the strain relief slot
 *      around the cable, snug but not crushing the wire
 *
 * 6. Test:
 *    - Plug the connector onto the Aerogen Solo cup pins
 *    - You should feel a slight click / resistance as the pins
 *      engage the pogo sockets
 *    - Measure continuity: < 1 ohm from each JST pin to the
 *      corresponding cup pin
 *
 * CABLE RECOMMENDATIONS:
 *   - Use flexible silicone-insulated wire (survives repeated flexing)
 *   - Keep cable length 30-50cm (shorter = less noise at 100+ kHz)
 *   - Twist the two wires together to reduce EMI pickup
 *   - The cable runs from the connector plug to the controller
 *     enclosure, through a PG7 cable gland in the enclosure wall
 *
 * All dimensions are now caliper-verified. Adjust plug_clearance
 *   ±0.1mm from 0.3mm if too tight or too loose after a test print.
 * ===================================================================== */
