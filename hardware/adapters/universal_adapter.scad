/*
 * universal_adapter.scad
 *
 * Parametric 3D-printable adapter for NON-AEROGEN nebulizer cups.
 * Supports multiple contact types: circular pads, ring contacts,
 * pin contacts, and strip contacts.
 *
 * Tested conceptually against:
 *   - OMRON MicroAir U22/U100
 *   - PARI eFlow / eFlow Rapid
 *   - Philips InnoSpire Go
 *   - Generic vibrating mesh nebulizer cups
 *
 * USAGE:
 *   1. Measure your nebulizer cup (see README.md measurement guide)
 *   2. Select the contact_type that matches your cup
 *   3. Enter measurements below
 *   4. Preview (F5), Render (F6), Export STL
 *   5. Print in PETG or PLA
 *
 * License: MIT
 */

/* =====================================================================
 * CUP PROFILE SELECTION
 *
 * Uncomment ONE profile below, or set "custom" and fill in measurements.
 * These profiles contain estimated dimensions — verify with your cup.
 * ===================================================================== */

cup_profile = "custom";  // "omron_u22", "pari_eflow", "philips_innospire", "custom"

/* =====================================================================
 * CUSTOM CUP MEASUREMENTS
 *
 * If cup_profile = "custom", these values are used directly.
 * If using a named profile, these are ignored (overridden below).
 * ===================================================================== */

// --- Cup body ---
_cup_shape           = "cylinder";  // "cylinder", "rectangle", "oval"
_cup_diameter        = 35.0;        // For cylinder/oval: outer diameter (or major axis)
_cup_diameter_minor  = 35.0;        // For oval: minor axis diameter (ignored for cylinder)
_cup_rect_width      = 40.0;        // For rectangle: width
_cup_rect_depth      = 30.0;        // For rectangle: depth
_cup_height          = 30.0;        // Total height
_cup_corner_radius   = 3.0;         // Corner radius for rectangle cups

// --- Contact type and dimensions ---
// Contact types:
//   "circular_pad" — two round pads (like Aerogen Solo)
//   "ring"         — concentric ring contacts (inner + outer ring)
//   "pin"          — protruding pin contacts that need socket receivers
//   "strip"        — flat strip/bar contacts
_contact_type        = "circular_pad";

// For circular_pad:
_pad_spacing         = 12.0;        // Center-to-center distance between pads
_pad_diameter        = 3.0;         // Diameter of each pad
_pad_inset           = 0.0;         // Recess depth below cup bottom

// For ring contacts:
_ring_outer_od       = 20.0;        // Outer ring outside diameter
_ring_outer_id       = 16.0;        // Outer ring inside diameter
_ring_inner_od       = 10.0;        // Inner ring/pad outside diameter
_ring_inner_id       = 6.0;         // Inner ring/pad inside diameter (0 = solid pad)

// For pin contacts:
_pin_spacing         = 8.0;         // Center-to-center distance between pins
_pin_diameter        = 1.5;         // Pin diameter
_pin_protrusion      = 2.0;         // How far pins stick out from cup bottom

// For strip contacts:
_strip_spacing       = 15.0;        // Center-to-center distance between strips
_strip_width         = 2.0;         // Width of each strip
_strip_length        = 10.0;        // Length of each strip

// --- Contact location on cup ---
_contacts_on         = "bottom";    // "bottom" or "side"
_contact_offset_x    = 0;           // Offset from cup center
_contact_offset_y    = 0;

/* =====================================================================
 * NAMED PROFILES — Estimated dimensions for common cups
 *
 * These are based on publicly available information and photographs.
 * You MUST verify measurements against your actual cup.
 * ===================================================================== */

// Profile resolution
cup_shape = (cup_profile == "omron_u22") ? "cylinder" :
            (cup_profile == "pari_eflow") ? "cylinder" :
            (cup_profile == "philips_innospire") ? "oval" :
            _cup_shape;

cup_diameter = (cup_profile == "omron_u22") ? 38.0 :
               (cup_profile == "pari_eflow") ? 42.0 :
               (cup_profile == "philips_innospire") ? 36.0 :
               _cup_diameter;

cup_height = (cup_profile == "omron_u22") ? 35.0 :
             (cup_profile == "pari_eflow") ? 45.0 :
             (cup_profile == "philips_innospire") ? 32.0 :
             _cup_height;

contact_type = (cup_profile == "omron_u22") ? "circular_pad" :
               (cup_profile == "pari_eflow") ? "circular_pad" :
               (cup_profile == "philips_innospire") ? "circular_pad" :
               _contact_type;

pad_spacing = (cup_profile == "omron_u22") ? 12.0 :
              (cup_profile == "pari_eflow") ? 14.0 :
              (cup_profile == "philips_innospire") ? 11.0 :
              _pad_spacing;

pad_diameter = (cup_profile == "omron_u22") ? 3.0 :
               (cup_profile == "pari_eflow") ? 3.5 :
               (cup_profile == "philips_innospire") ? 2.5 :
               _pad_diameter;

/* =====================================================================
 * POGO PIN SPECIFICATIONS
 * ===================================================================== */

pogo_body_diameter  = 1.02;     // P75-B1 pogo pin barrel diameter
pogo_total_length   = 16.5;     // Total length
pogo_travel         = 1.5;      // Spring travel
pogo_preload        = 1.0;      // Pre-compression when cup is seated

/* =====================================================================
 * ADAPTER DESIGN PARAMETERS
 * ===================================================================== */

cup_clearance       = 0.4;      // Gap between cup and cradle wall
pogo_clearance      = 0.15;     // Gap around pogo pin in channel
wall_thickness      = 2.5;
base_thickness      = 8.0;
cup_cradle_depth    = 15.0;
cable_channel_width = 6.0;
cable_channel_height= 4.0;

use_magnets         = true;
magnet_diameter     = 6.0;
magnet_thickness    = 2.0;

use_dovetail        = true;     // Dovetail for enclosure mounting
dovetail_width      = 10.0;
dovetail_height     = 4.0;

$fn = 64;

/* =====================================================================
 * COMPUTED DIMENSIONS
 * ===================================================================== */

cradle_id = cup_diameter + cup_clearance * 2;
cradle_od = cradle_id + wall_thickness * 2;
total_height = base_thickness + cup_cradle_depth;
pogo_channel_d = pogo_body_diameter + pogo_clearance * 2;

/* =====================================================================
 * CONTACT-SPECIFIC POGO PIN PLACEMENT
 *
 * Different contact types need different pogo pin arrangements.
 * ===================================================================== */

module place_pogo_channels() {
    if (contact_type == "circular_pad") {
        // Two pogo pins at pad locations
        for (i = [-1, 1]) {
            translate([_contact_offset_x + i * pad_spacing / 2,
                       _contact_offset_y, 0])
                pogo_channel();
        }
    }
    else if (contact_type == "ring") {
        // Two pogo pins: one on inner ring, one on outer ring
        // Inner contact (center area)
        inner_r = (_ring_inner_od + _ring_inner_id) / 4;  // Middle of inner ring
        translate([_contact_offset_x, _contact_offset_y + inner_r, 0])
            pogo_channel();

        // Outer contact
        outer_r = (_ring_outer_od + _ring_outer_id) / 4;  // Middle of outer ring
        translate([_contact_offset_x, _contact_offset_y - outer_r, 0])
            pogo_channel();
    }
    else if (contact_type == "pin") {
        // Socket receivers for protruding pins
        for (i = [-1, 1]) {
            translate([_contact_offset_x + i * _pin_spacing / 2,
                       _contact_offset_y, 0])
                pin_socket();
        }
    }
    else if (contact_type == "strip") {
        // Multiple pogo pins along each strip for reliable contact
        for (i = [-1, 1]) {
            x = _contact_offset_x + i * _strip_spacing / 2;
            // Place 2 pins per strip for redundancy
            for (j = [-1, 1]) {
                translate([x, _contact_offset_y + j * _strip_length * 0.3, 0])
                    pogo_channel();
            }
        }
    }
}

module pogo_channel() {
    // Vertical channel for one pogo pin
    translate([0, 0, -0.1])
        cylinder(d=pogo_channel_d, h=base_thickness + pogo_preload + 0.2);

    // Wider recess at bottom for solder cup
    translate([0, 0, -0.1])
        cylinder(d=pogo_channel_d + 1.5, h=4.1);
}

module pin_socket() {
    // For cups with protruding pins: a socket hole that receives the pin
    // and makes contact via a compression spring or friction fit
    socket_d = _pin_diameter + 0.3;  // Slight clearance for pin entry

    // Socket hole from top (pin enters here)
    translate([0, 0, base_thickness - _pin_protrusion - 0.5])
        cylinder(d=socket_d, h=_pin_protrusion + cup_cradle_depth + 1);

    // Wider channel below for wire/spring contact
    translate([0, 0, -0.1])
        cylinder(d=socket_d + 2.0, h=base_thickness - _pin_protrusion);

    // Wire exit at bottom
    translate([0, 0, -0.1])
        cylinder(d=pogo_channel_d + 1.5, h=4.1);
}

/* =====================================================================
 * CUP BORE — Adapts to cup shape
 * ===================================================================== */

module cup_bore() {
    if (cup_shape == "cylinder") {
        cylinder(d=cradle_id, h=cup_cradle_depth + 1);
    }
    else if (cup_shape == "oval") {
        minor_id = _cup_diameter_minor + cup_clearance * 2;
        scale([1, minor_id / cradle_id, 1])
            cylinder(d=cradle_id, h=cup_cradle_depth + 1);
    }
    else if (cup_shape == "rectangle") {
        rect_w = _cup_rect_width + cup_clearance * 2;
        rect_d = _cup_rect_depth + cup_clearance * 2;
        r = _cup_corner_radius;
        linear_extrude(height=cup_cradle_depth + 1)
            offset(r=r)
                offset(delta=-r)
                    square([rect_w, rect_d], center=true);
    }
}

/* =====================================================================
 * OUTER BODY — Matches cup bore shape with wall thickness
 * ===================================================================== */

module outer_body() {
    if (cup_shape == "cylinder") {
        cylinder(d=cradle_od, h=total_height);
    }
    else if (cup_shape == "oval") {
        minor_od = _cup_diameter_minor + cup_clearance * 2 + wall_thickness * 2;
        scale([1, minor_od / cradle_od, 1])
            cylinder(d=cradle_od, h=total_height);
    }
    else if (cup_shape == "rectangle") {
        rect_w = _cup_rect_width + cup_clearance * 2 + wall_thickness * 2;
        rect_d = _cup_rect_depth + cup_clearance * 2 + wall_thickness * 2;
        r = _cup_corner_radius + wall_thickness;
        linear_extrude(height=total_height)
            offset(r=r)
                offset(delta=-r)
                    square([rect_w, rect_d], center=true);
    }
}

/* =====================================================================
 * WIRE CHANNEL AND CABLE EXIT
 * ===================================================================== */

module wire_channel() {
    translate([-cradle_od/2 - 1, -cable_channel_width/2, 1.5])
        cube([cradle_od, cable_channel_width, cable_channel_height]);
}

module cable_exit() {
    translate([-cradle_od/2 - 0.1, 0, 1.5 + cable_channel_height/2])
        rotate([0, 90, 0])
            cylinder(d=cable_channel_height + 1, h=wall_thickness + 0.2);
}

/* =====================================================================
 * MAGNET POCKETS
 * ===================================================================== */

module magnet_pockets() {
    for (angle = [60, 300]) {  // Avoid cable exit side (180 deg)
        x = (cradle_od/2 - magnet_thickness/2 - 0.5) * cos(angle);
        y = (cradle_od/2 - magnet_thickness/2 - 0.5) * sin(angle);

        translate([x, y, base_thickness + cup_cradle_depth/2])
            rotate([0, 0, angle])
                rotate([0, 90, 0])
                    cylinder(d=magnet_diameter + 0.2, h=magnet_thickness + 0.1);
    }
}

/* =====================================================================
 * ENTRY CHAMFER
 * ===================================================================== */

module entry_chamfer() {
    chamfer_size = 2.0;
    translate([0, 0, total_height])
        difference() {
            cylinder(d=cradle_od + 0.2, h=chamfer_size);
            translate([0, 0, -0.1])
                cylinder(d1=cradle_id, d2=cradle_id + chamfer_size * 2, h=chamfer_size + 0.2);
        }
}

/* =====================================================================
 * DOVETAIL RAIL
 * ===================================================================== */

module dovetail_rail() {
    if (use_dovetail) {
        rail_length = cradle_od * 0.8;
        translate([0, 0, -dovetail_height])
            linear_extrude(height=dovetail_height)
                square([rail_length, dovetail_width], center=true);
    }
}

/* =====================================================================
 * MAIN ASSEMBLY
 * ===================================================================== */

difference() {
    union() {
        outer_body();
        if (use_dovetail)
            dovetail_rail();
    }

    // Cup pocket
    translate([0, 0, base_thickness])
        cup_bore();

    // Contact channels
    place_pogo_channels();

    // Wiring
    wire_channel();
    cable_exit();

    // Retention magnets
    if (use_magnets)
        magnet_pockets();

    // Entry chamfer
    entry_chamfer();
}

/* =====================================================================
 * NOTES FOR SPECIFIC CUP BRANDS
 *
 * OMRON MicroAir U22/U100:
 *   - Cylindrical cup with two bottom contact pads
 *   - Cup snaps into a proprietary controller cradle
 *   - Verify pad spacing and diameter with your unit
 *   - May need slightly wider sweep range (80-160 kHz)
 *
 * PARI eFlow / eFlow Rapid:
 *   - Larger cup body than Aerogen
 *   - Electronic module normally clips onto the cup
 *   - Contact pads are on the base of the cup
 *   - Higher power requirements — start voltage low
 *
 * Philips InnoSpire Go:
 *   - Compact, slightly oval cross-section
 *   - Contacts on bottom
 *   - Limited public data — test very cautiously
 *
 * For ALL non-Aerogen cups:
 *   - Start with LOW boost voltage (DAC=8 or module set to ~8V)
 *   - Widen the sweep range in config.h if needed
 *   - Monitor cup temperature — if it gets warm, reduce voltage
 *   - Test with saline only until operation is confirmed
 * ===================================================================== */
