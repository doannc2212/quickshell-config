pragma Singleton
import Quickshell

Singleton {
    // Logical (un-scaled, rotation-aware) width of a monitor
    function logicalW(m) {
        return (m.transform % 2 === 0) ? m.width / m.scale : m.height / m.scale;
    }

    // Logical (un-scaled, rotation-aware) height of a monitor
    function logicalH(m) {
        return (m.transform % 2 === 0) ? m.height / m.scale : m.width / m.scale;
    }

    // Parse a mode string like "1920x1080@60.00Hz"
    // Returns { w, h, rate } or null if the string doesn't match
    function parseMode(modeStr) {
        const match = modeStr.match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
        if (!match) return null;
        return { w: parseInt(match[1]), h: parseInt(match[2]), rate: match[3] };
    }

    // Axis-aligned bounding-box overlap test for two rectangles
    function overlapsAABB(ax, ay, aw, ah, bx, by, bw, bh) {
        return ax < bx + bw && ax + aw > bx &&
               ay < by + bh && ay + ah > by;
    }
}
