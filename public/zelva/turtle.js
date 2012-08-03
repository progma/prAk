function jdi(n)
{
    var novaPoziceX = poziceX + n*Math.sin(uhel/360*Math.PI*2);
    var novaPoziceY = poziceY - n*Math.cos(uhel/360*Math.PI*2);
    turtle.drawLine(poziceX, poziceY, novaPoziceX, novaPoziceY);
    poziceX = novaPoziceX;
    poziceY = novaPoziceY;
}

function doprava(u)
{
    uhel = (uhel + u) % 360;
}

turtle = {
    run: function(code, canvas) {
        poziceX = 0;
        poziceY = 0;
        uhel = 0;

        if (turtle.paper)
        {
            turtle.paper.remove();
        }

        var paper = Raphael(canvas, 200, 200);
        turtle.paper = paper;
        eval(code);
        turtle.drawTurtle();
    },

    drawLine: function(fromX, fromY, toX, toY) {
        turtle.paper.path("M" + (fromX+100) + " " + (fromY+100) + "L" + (toX+100) + " " + (toY+100));
    },

    drawTurtle: function() {
        return;
    }
}