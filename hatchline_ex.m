%% example 1, control step response

t = linspace(0, 10, 1001);
omega = 4;
omegad = omega.*sqrt(1-zeta.^2);
zeta = 0.5;
alpha = omega.*zeta;
y = 1.0 - sqrt(alpha.^2+omegad.^2)./omegad.*exp(-alpha.*t).*sin(omegad.*t + acos(zeta));

tlim = [0.00, 1.00, 1.00, 2.00, 2.00, 10.00];
llim = [0.00, 0.00, 0.90, 0.90, 0.95,  0.95];
ulim = [1.20, 1.20, 1.20, 1.20, 1.05,  1.05];
figure;
ha = axes;hold on;grid on;box on;
ha.YLim = [-0.1, 1.3];
ha.XLim = [t(1), t(end)];
plot(t, y);
% plot(tlim, llim)
hatchline(tlim, llim, Angle=-60, Spacing=0.15);
hatchline(tlim, ulim, Angle=60, Spacing=0.15);
% plot(tlim, ulim)

%% example 2, method comparisons
figure;
tiledlayout(1, 2);
ha = nexttile;hold on;grid on;box on;
axis equal;
title("Method=Absolute (default)")
subtitle("Angle is constant with respect to axes")
ha.XLim = [-1.2, 1.2];
ha.YLim = [-1.2, 1.2];
t = linspace(0, 360, 361);
x = cosd(t);
y = sind(t);

hatchline(x, y);


ha = nexttile;hold on;grid on;box on;
axis equal;
title("Method=Relative");
subtitle("Angle is relative to line");
ha.XLim = [-1.2, 1.2];
ha.YLim = [-1.2, 1.2];
hatchline(x, y, Method="Relative");

%% example 3, check clip to line with relative angle
figure(Name="Example3");
ha = axes;hold on;grid on;box on;
ha.XLim = [0, 1.0];
ha.YLim = [0, 1.0];
x = [0, 0.5, 0.5, 1.0];
y = [0.2, 0.2, 0.8, 0.8];
hatchline(x, y, Method="Relative", Angle=-30);

%% example 4, different settings for line and hatch
% plot hatch separately
figure(Name="Example4");
ha = axes;hold on;grid on;box on;
x = linspace(0, 4*pi, 100);
y = sin(x);
plot(x, y, "-", LineWidth=1.5);
hatchline(x, y, LineWidth=0.75, Method="Relative", PlotBounds=false);