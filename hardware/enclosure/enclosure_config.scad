/*
 * enclosure_config.scad
 *
 * Shared parameters and helper modules for the v3.1 controller enclosure.
 * Included from both controller_enclosure.scad (base) and
 * controller_enclosure_lid.scad (lid) so that dimensions stay in one place.
 *
 * v3.1 changes over v3.0:
 *   - AAA compartment replaced with a LiPo + TP4056 charging bay
 *   - PCB cavity raised to clear the LCD backpack pins
 *   - New 16x2 character LCD window + mounting posts on the lid
 *   - USB-C aperture moved to the battery bay front wall (TP4056 charge port)
 *
 * License: MIT
 */

/* =====================================================================
 * PCB DIMENSIONS
 *
 * The JLCPCB turnkey board is a 2-layer ~50x70mm FR4 PCB. Increase
 * pcb_component_height if you add taller modules to the board — it
 * directly sets how much headroom the lid leaves above the PCB, and
 * therefore how much room the LCD I2C backpack has to hang down into.
 * ===================================================================== */

pcb_width            = 50.0;    // X — short edge
pcb_depth            = 70.0;    // Y — long edge
pcb_thickness        = 1.6;     // Standard FR4
pcb_component_height = 18.0;    // Tallest top-side component + clearance
                                // (v3.1 raised from 12 -> 18 to clear the
                                //  LCD I2C backpack hanging down from the lid)
pcb_bottom_clearance = 2.0;
pcb_corner_radius    = 2.0;

pcb_mount_holes      = true;
mount_hole_diameter  = 2.7;     // For M2.5 screws
mount_hole_inset_x   = 3.5;
mount_hole_inset_y   = 3.5;
mount_standoff_h     = 3.0;

/* =====================================================================
 * LIPO BATTERY BAY (replaces v3.0's 3xAAA holder)
 *
 * Default is a 1S 2000mAh 103450 pouch cell (~50 x 34 x 10 mm). Any
 * pouch cell up to these dimensions will drop in. If you substitute a
 * larger cell, widen lipo_d / lipo_w here and reprint.
 * ===================================================================== */

battery_enable   = true;

lipo_w           = 36.0;    // Cell width + clearance (cell is ~34mm)
lipo_d           = 54.0;    // Cell length + clearance (cell is ~52mm)
lipo_h           = 11.0;    // Cell thickness + clearance (cell is ~10mm)

/* =====================================================================
 * TP4056 CHARGING MODULE
 *
 * Small PCB with USB-C input, DW01A protection and TP4056 charger IC.
 * It sits ABOVE the LiPo on an internal shelf, with the USB-C socket
 * facing out through a cutout in the bay's front wall. Typical modules
 * are ~25 x 18 x 6 mm with the USB-C socket protruding ~2 mm.
 * ===================================================================== */

tp4056_enable    = true;
tp4056_w         = 22.0;    // Module PCB width + clearance
tp4056_d         = 28.0;    // Module PCB depth including USB-C protrusion
tp4056_h         =  7.0;    // Module thickness (PCB + USB-C socket)
tp4056_shelf_t   =  1.5;    // Shelf wall thickness between LiPo and module
tp4056_usbc_w    =  9.5;    // USB-C aperture width
tp4056_usbc_h    =  3.5;    // USB-C aperture height

// Total height of the battery bay (LiPo + shelf + TP4056 + clearance)
battery_bay_h    = lipo_h + tp4056_shelf_t + tp4056_h + 2.5;
battery_bay_w    = max(lipo_w, tp4056_w);
battery_bay_d    = max(lipo_d, tp4056_d);

battery_wall     = 1.8;     // Wall between battery bay and PCB cavity
battery_clearance= 0.8;     // Extra clearance inside the bay

/* =====================================================================
 * 16x2 CHARACTER LCD WITH I2C BACKPACK
 *
 * Standard HD44780 1602 module, PCF8574 backpack. Mounts to the lid on
 * four M3 standoffs with the glass viewable through a rectangular window.
 *
 * Default dimensions are for the most common JHD162A-type module. Measure
 * yours and adjust if needed — especially the mount-hole spacing.
 * ===================================================================== */

lcd_enable            = true;

lcd_pcb_w             = 80.0;   // LCD PCB width
lcd_pcb_d             = 36.0;   // LCD PCB depth
lcd_pcb_thickness     =  1.6;
lcd_backpack_drop     = 11.0;   // Distance backpack hangs below the LCD PCB

lcd_viewing_w         = 72.0;   // Cutout width (generous fit around the glass)
lcd_viewing_h         = 26.0;   // Cutout height

// LCD position on the lid. Because the LCD PCB (~80 mm wide) is nearly
// as wide as the whole enclosure, it must be centered on the ENCLOSURE
// (x = 0), not on the PCB cavity — otherwise the window and the left
// mount standoff fall off the edge of the lid and break the seal.
lcd_window_offset_x   =  0.0;   // Window center X (0 = enclosure center)
lcd_window_offset_y   = 12.0;   // Window center Y (+Y = toward rear wall)

// Mount holes (measured from LCD PCB center)
lcd_mount_dx          = 75.0;   // X spacing between hole centers
lcd_mount_dy          = 31.0;   // Y spacing between hole centers
lcd_mount_hole_dia    =  3.2;   // M3 clearance
lcd_standoff_od       =  6.0;   // Standoff outer diameter
lcd_standoff_h        =  4.0;   // Standoff height below lid inner surface

/* =====================================================================
 * ENCLOSURE ENVELOPE
 * ===================================================================== */

wall_thickness     = 2.5;
base_height_extra  = 2.0;
lid_lip_height     = 3.0;
lid_lip_clearance  = 0.3;

// --- PCB cavity ---
int_pcb_width  = pcb_width + 2.0;
int_pcb_depth  = pcb_depth + 2.0;
int_pcb_height = pcb_bottom_clearance + pcb_thickness + pcb_component_height + 2.0;

// --- Battery bay cavity ---
int_bat_width  = battery_enable ? battery_bay_w + battery_clearance * 2 : 0;
int_bat_depth  = battery_enable ? battery_bay_d + battery_clearance * 2 : 0;
int_bat_height = battery_enable ? battery_bay_h + battery_clearance     : 0;

// --- Overall internal envelope ---
int_width  = int_pcb_width + (battery_enable ? battery_wall + int_bat_width : 0);
int_depth  = max(int_pcb_depth, battery_enable ? int_bat_depth : 0);
int_height = max(int_pcb_height, int_bat_height);

// --- External envelope ---
ext_width  = int_width + wall_thickness * 2;
ext_depth  = int_depth + wall_thickness * 2;
ext_height = int_height + wall_thickness + base_height_extra;
corner_r   = pcb_corner_radius + 1.0;

// --- Section offsets (X is positive to the right) ---
pcb_offset_x = battery_enable ? -(int_bat_width + battery_wall) / 2 : 0;
bat_offset_x = battery_enable ?  (int_pcb_width + battery_wall) / 2 : 0;

/* =====================================================================
 * CONNECTORS AND OPENINGS
 * ===================================================================== */

// USB-C charging aperture on the TP4056 front edge
// (formerly a PCB-mounted USB-C receptacle; v3.1 charges through TP4056)
usb_c_enable   = true;
usb_c_width    = 9.5;
usb_c_height   = 3.5;

// Cable gland for the connector-plug pigtail (rear short edge, PCB side)
cable_enable        = true;
cable_hole_diameter = 6.0;
cable_z_offset      = mount_standoff_h + pcb_thickness + 3.0;

// ICSP programming header slot
icsp_enable    = true;
icsp_width     = 14.0;
icsp_height    = 3.0;
icsp_z_offset  = mount_standoff_h + pcb_thickness + 1.0;

// LCD cable slot between the PCB cavity and the lid-mounted LCD.
// The 4-wire I2C ribbon runs through this gap.
lcd_wire_slot_w  = 5.0;
lcd_wire_slot_h  = 3.0;

/* =====================================================================
 * USER INTERFACE (on the lid)
 * ===================================================================== */

// The LCD occupies the upper half of the lid; the button + LEDs
// live in the lower half, over the PCB area where the existing
// tactile switch and LED packages are mounted on the board.

button_enable   = true;
button_diameter = 8.0;
button_x        = pcb_offset_x - int_pcb_width/4;
button_y        = -int_depth/4 + 2.0;    // Pushed toward the rear wall

led_enable      = true;
led_diameter    = 3.5;
led_red_x       = pcb_offset_x + int_pcb_width/4;
led_red_y       = -int_depth/4 + 2.0;
led_green_x     = pcb_offset_x + int_pcb_width/4;
led_green_y     = -int_depth/4 + 10.0;

/* =====================================================================
 * VENTILATION
 * ===================================================================== */

vent_enable       = true;
vent_slot_width   = 1.5;
vent_slot_length  = 15.0;
vent_slot_count   = 4;
vent_slot_spacing = 4.0;

/* =====================================================================
 * VISUAL
 * ===================================================================== */

$fn = 48;

/* =====================================================================
 * SHARED HELPER MODULES
 * ===================================================================== */

module rounded_box(w, d, h, r) {
    linear_extrude(height=h)
        offset(r=r)
            offset(delta=-r)
                square([w, d], center=true);
}
