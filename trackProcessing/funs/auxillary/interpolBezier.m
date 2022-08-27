function [Qxy] = interpolBezier(inx,iny,n)
% Px contains x-coordinates of control points [Px0,Px1,Px2,Px3]
% Py contains y-coordinates of control points [Py0,Py1,Py2,Py3]
% n is number of intervals
% Equation of Bezier Curve, utilizes Horner's rule for efficient computation.
% Q(t)=(-P0 + 3*(P1-P2) + P3)*t^3 + 3*(P0-2*P1+P2)*t^2 + 3*(P1-P0)*t + Px0
% 
% Modified after: Dr. Murtaza Khan.  Email : drkhanmurtaza@gmail.com

Px0=inx(2);
Py0=iny(2);
Px1=inx(2)+(Px0-inx(1));
Py1=iny(2)+(Py0-iny(1));
Px3=inx(3);
Py3=iny(3);
Px2=inx(3)+(Px3-inx(4));
Py2=iny(3)+(Py3-iny(4));
cx3=-Px0 + 3*(Px1-Px2) + Px3;
cy3=-Py0 + 3*(Py1-Py2) + Py3;
cx2=3*(Px0-2*Px1+Px2); 
cy2=3*(Py0-2*Py1+Py2);
cx1=3*(Px1-Px0);
cy1=3*(Py1-Py0);
cx0=Px0;
cy0=Py0;
dt=1/n;
Qx(1)=Px1; % Qx at t=1
Qy(1)=Py1; % Qy at t=1
for i=1:n  
    t=i*dt;
    Qx(i+1,1)=((cx3*t+cx2)*t+cx1)*t + cx0;
    Qy(i+1,1)=((cy3*t+cy2)*t+cy1)*t + cy0;    
end
Qxy = [Qx(2:end) Qy(2:end); ];
