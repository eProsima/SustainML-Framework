.pragma library

// Marker shapes of the series of a chart, the second encoding next to their colour
var shapes = ["circle", "square", "triangle", "diamond", "triangle_down", "plus"]

// Adds the path of the marker of series j, centred at (x, y) with radius r, to ctx
function path(ctx, j, x, y, r)
{
    var shape = shapes[j % shapes.length]
    ctx.beginPath()
    if (shape === "square")
        ctx.rect(x - r * 0.85, y - r * 0.85, r * 1.7, r * 1.7)
    else if (shape === "triangle") {
        ctx.moveTo(x, y - r * 1.1); ctx.lineTo(x + r, y + r * 0.75); ctx.lineTo(x - r, y + r * 0.75); ctx.closePath()
    }
    else if (shape === "triangle_down") {
        ctx.moveTo(x, y + r * 1.1); ctx.lineTo(x + r, y - r * 0.75); ctx.lineTo(x - r, y - r * 0.75); ctx.closePath()
    }
    else if (shape === "diamond") {
        ctx.moveTo(x, y - r * 1.15); ctx.lineTo(x + r * 1.15, y); ctx.lineTo(x, y + r * 1.15); ctx.lineTo(x - r * 1.15, y); ctx.closePath()
    }
    else if (shape === "plus") {
        var a = r * 1.1, b = r * 0.4
        ctx.moveTo(x - b, y - a); ctx.lineTo(x + b, y - a); ctx.lineTo(x + b, y - b); ctx.lineTo(x + a, y - b)
        ctx.lineTo(x + a, y + b); ctx.lineTo(x + b, y + b); ctx.lineTo(x + b, y + a); ctx.lineTo(x - b, y + a)
        ctx.lineTo(x - b, y + b); ctx.lineTo(x - a, y + b); ctx.lineTo(x - a, y - b); ctx.lineTo(x - b, y - b)
        ctx.closePath()
    }
    else
        ctx.arc(x, y, r, 0, 2 * Math.PI)
}
