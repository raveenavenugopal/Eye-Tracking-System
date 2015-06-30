function re = ddaline(x0,y0,x1,y1)

import java.awt.Robot;
mouse=Robot;

dx = abs(x1-x0);
dy = abs(y1-y0);
sx = sign(x1-x0);
sy = sign(y1-y0);
if (dy > dx)
    step = dy;
else 
    step = dx;
end
x(1) = x0; y(1) = y0; j = 1;
for i= 0:1:step
    if (x1 == x)&(y1 == y)
        break;
    end
    j = j+1;
    x(j) = x(j-1) + (dx/step)*sx;
    y(j) = y(j-1) + (dy/step)*sy;  
    mouse.mouseMove(x(j), y(j));
    pause(0.00001);
end
