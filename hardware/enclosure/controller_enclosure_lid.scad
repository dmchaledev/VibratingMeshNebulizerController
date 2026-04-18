/*
 * controller_enclosure_lid.scad
 *
 * v3.1 lid for the vibrating mesh nebulizer controller enclosure.
 * Renders ONLY the lid. The matching base is in
 * controller_enclosure.scad. Shared dimensions are in
 * enclosure_config.scad.
 *
 * Features:
 *   - Rectangular viewing window for a 16x2 character LCD or OLED
 *   - Four M3 standoffs for mounting the LCD PCB from below
 *   - Button pass-through for the tactile start/stop switch
 *   - Two LED light pipes (red / green status)
 *   - Slim ventilation slots over the PCB area
 *
 * USAGE:
 *   1. (Optional) adjust parameters in enclosure_config.scad
 *   2. Preview (F5), Render (F6), Export STL
 *   3. Print upside down (outer surface on the build plate),
 *      PETG, 0.2mm layer, 30-50% infill, supports OFF
 *
 * License: MIT
 */

include <enclosure_config.scad>;

/* =====================================================================
 * ENCLOSURE LID
 * ===================================================================== */

module enclosure_lid() {
    difference() {
        union() {
            // Outer lid plate
            rounded_box(ext_width, ext_depth, wall_thickness, corner_r);

            // Inner lip that drops into the base
            translate([0, 0, wall_thickness])
                rounded_box(ext_width - wall_thickness * 2,
                            ext_depth - wall_thickness * 2,
                            lid_lip_height,
                            max(0.5, corner_r - wall_thickness));

            // LCD mounting standoffs rise from the lid's inner surface
            if (lcd_enable)
                lcd_standoffs();
        }

        // === LCD viewing window ===
        // Centered on the ENCLOSURE (lcd_window_offset_x = 0 by default),
        // not on pcb_offset_x — the LCD is nearly as wide as the lid, so
        // biasing it toward the PCB cavity would push the window past the
        // left edge of the lid and break the perimeter seal.
        if (lcd_enable)
            translate([lcd_window_offset_x, lcd_window_offset_y, -0.1])
                linear_extrude(height=wall_thickness + 0.2)
                    offset(r=0.8)
                        offset(delta=-0.8)
                            square([lcd_viewing_w, lcd_viewing_h], center=true);

        // === LCD screw holes through the standoffs ===
        if (lcd_enable)
            lcd_mount_holes();

        // === Button hole ===
        if (button_enable)
            translate([button_x, button_y, -0.1])
                cylinder(d=button_diameter, h=wall_thickness + 0.2);

        // === LED windows ===
        if (led_enable) {
            translate([led_red_x, led_red_y, -0.1])
                cylinder(d=led_diameter, h=wall_thickness + 0.2);
            translate([led_green_x, led_green_y, -0.1])
                cylinder(d=led_diameter, h=wall_thickness + 0.2);
        }

        // === Lid vents over the PCB area (not the LCD) ===
        // Slotted across the lower half of the lid so mist deposits
        // can't accumulate in a concave pocket.
        if (vent_enable)
            for (i = [0:vent_slot_count-1]) {
                translate([pcb_offset_x - vent_slot_length/2,
                           -ext_depth/2 + wall_thickness + 6 + i * vent_slot_spacing,
                           -0.1])
                    cube([vent_slot_length, vent_slot_width, wall_thickness + 0.2]);
            }

        // === LCD wire slot (matches the base-side notch in the lip) ===
        if (lcd_enable)
            translate([pcb_offset_x + int_pcb_width/4 - lcd_wire_slot_w/2,
                       -ext_depth/2 + wall_thickness - 0.1,
                       wall_thickness - 0.1])
                cube([lcd_wire_slot_w,
                      wall_thickness + 0.2,
                      lid_lip_height + 0.3]);

        // === Label recess — small "VMN" text on the OUTER lid face ===
        // The lid is printed upside down (outer face on the build plate),
        // so the outer face is at z = 0 in the model. Recess the text from
        // there into the plate so it's visible after flipping. The previous
        // version recessed at z = wall_thickness - 0.4, which put the text
        // on the INNER face and made it invisible from outside.
        translate([pcb_offset_x, -ext_depth/2 + 6, -0.1])
            linear_extrude(height=0.5)
                text("VMN", size=4.5, halign="center", valign="center",
                     font="Liberation Sans:style=Bold");
    }
}

/* =====================================================================
 * LCD MOUNTING STANDOFFS
 *
 * Four cylindrical posts that rise from the inside of the lid. The
 * LCD PCB bolts up into these with short M3 screws from below.
 * Keep the posts comfortably inside the inner lip so they clear the
 * base walls when the lid drops on.
 * ===================================================================== */

module lcd_standoffs() {
    /* Start the standoff base 0.05 mm INSIDE the lid plate (not at exactly
     * z = wall_thickness) so the CGAL union fuses standoff geometry to
     * the plate. Without the overlap each standoff renders as its own
     * disconnected volume — slicers may then drop the floating posts. */
    overlap = 0.05;
    for (sx = [-1, 1])
        for (sy = [-1, 1])
            translate([lcd_window_offset_x + sx * lcd_mount_dx/2,
                       lcd_window_offset_y + sy * lcd_mount_dy/2,
                       wall_thickness - overlap])
                cylinder(d=lcd_standoff_od, h=lcd_standoff_h + overlap);
}

module lcd_mount_holes() {
    for (sx = [-1, 1])
        for (sy = [-1, 1])
            translate([lcd_window_offset_x + sx * lcd_mount_dx/2,
                       lcd_window_offset_y + sy * lcd_mount_dy/2,
                       -0.1])
                cylinder(d=lcd_mount_hole_dia,
                         h=wall_thickness + lcd_standoff_h + 0.2);
}

/* =====================================================================
 * RENDER
 * ===================================================================== */

enclosure_lid();

/* =====================================================================
 * PRINT NOTES
 *
 *   - Orient the lid upside down: outer (show) face on the build plate,
 *     standoffs pointing up. No supports needed.
 *   - The LCD viewing window is a clean through-cut; bridge the top of
 *     the standoff holes cleanly by using 0.2 mm layers.
 *   - If your LCD module has slightly different mount-hole spacing,
 *     edit lcd_mount_dx / lcd_mount_dy in enclosure_config.scad.
 *
 * ===================================================================== */
