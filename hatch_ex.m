%% hatch_ex.m  —  Examples for the hatch() function
%
%   Demonstrates usage from basic calls through more advanced options.
%   Run each section (Ctrl+Enter) or the whole script at once.
close all
clear
clc

%% Example 1: Basic usage — square with default hatch settings
%   45-degree hatch, 12pt spacing, black lines, no fill.
figure('Name', 'Example 1 — Basic');
hatch([0 1 1 0], [0 0 1 1]);
title('Basic usage — defaults (45°, 12 pt)');

%% Example 2: Change angle and spacing
%   30-degree hatch at 12pt spacing.
figure('Name', 'Example 2 — Angle & Spacing');
axes;hold on;
title('Example 2 - Angle = 30°, Spacing = 20 pt');
subtitle("Markers show each hatch line drawn by just 2 points");
hatch([0 1 1 0], [0 0 1 1], Angle=30, Spacing=20, Marker="o");


%% Example 3: Specify a polygon face color (positional)
%   Passing a third positional argument sets the face color behind the
%   hatch lines (equivalent to FaceColor).
figure('Name', 'Example 3 - Triangle');
ha = axes; hold on;
title('Example 3 - Triangle');
subtitle("Fix axes limits before drawing to avoid skewing hatch pattern")
axis equal;
ha.XLim = [-0.2, 1.2];
ha.YLim = [-0.2, 1.2];
hatch([0 1 0.5], [0 0 1], Angle=-45);


%% Example 4: Fine hatching with custom line color
%   Dense, red hatching at a shallow angle.
figure('Name', 'Example 4 — Custom line color');
ha = axes;hold on;
title('Example 4 - Dense red hatching, 15°, 4 pt');
axis equal;
ha.XLim = [-0.2, 1.2];
ha.YLim = [-0.2, 1.2];
hatch([0 1 1 0], [0 0 1 1], Color='r', Spacing=4, Angle=15);

%% Example 5: Cross-hatch by layering two hatch calls
%   Combine two hatch objects on the same axes for a cross-hatch effect.
figure('Name', 'Example 5 — Cross-hatch');
ha = axes; hold on;
title('Example 5 - Cross-hatch (two layers)');
axis equal;
ha.XLim = [-0.2, 1.2];
ha.YLim = [-0.2, 1.2];
hatch([0 1 1 0], [0 0 1 1], Angle=45, Color=ha.XColor, Spacing=18);
hatch([0 1 1 0], [0 0 1 1], Angle=-45, Color=ha.XColor, Spacing=18);


%% Example 6: Hatch without boundary
figure('Name', 'Example 6 — No boundary');
ha = axes;hold on;
title('Example 6: Hatch w/o boundary');
axis equal;
ha.XLim = [-0.2, 1.2];
ha.YLim = [-0.2, 1.2];
hatch([0 1 1 0], [0 0 1 1], PlotBounds=false);

%% Example 7: Non-rectangular polygon on a shared axes
%   Hatch a pentagon on a different axes.
figure('Name', 'Example 7 — Non-rectangular polygon');
tiledlayout(1, 2);
ha = nexttile; hold on;
title('Pentagon with green hatch');

% leave a 2nd axes as current axes
nexttile;hold on;
title("Intentionally Blank");

% Draw pattern on first axes
theta = (90:72:90+360-72) * pi/180;
px = 0.5 + 0.45 * cos(theta);
py = 0.5 + 0.45 * sin(theta);
hatch(px, py, ...
  Angle=45, Spacing=7, Color=[0 0.5 0], Parent=ha);



%% Example 8: Self-intersecting polygon — pentagram (5-pointed star)
%   The vertices are ordered to trace the star outline by connecting every
%   other point of a regular pentagon.  This produces 5 edge crossings,
%   creating a self-intersecting polygon.  The even-odd inside test used
%   internally means only the five outer triangular points are hatched,
%   not the central pentagonal region (which winds twice).
figure(Name="Example 8 — Self-intersecting pentagram");
ha = axes;hold on;
axis equal;
ha.XLim = [-1.2, 1.2];
ha.YLim = [-1.2, 1.2];
title("Example 8 - Self-intersecting pentagram (even-odd hatching)");

% Build pentagram vertex sequence: skip every other tip of a circle
nPts     = 5;
tipAngle = (90 : -360/nPts : 90 - 360 + 360/nPts) * pi/180;
tipOrder = mod((0 : nPts-1) * 2, nPts) + 1;   % connect every 2nd tip
starX    = cos(tipAngle(tipOrder));
starY    = sin(tipAngle(tipOrder));

hatch(starX, starY);



%% Example 9, hatch lines at 0 and 90 deg
figure(Name="Example 9 — Edge Cases");
tiledlayout(1, 2);
ha = nexttile;hold on;
axis equal;
ha.XLim = [-0.2, 1.2];
ha.YLim = [-0.2, 1.2];
drawnow;
hatch([0 1 1 0], [0 0 1 1], Angle=0);
hatch([0 1 1], [0 0 1], Angle=90);
title("Example 9 - Lines at 0 and 90 deg");
subtitle("Note default colors obey line color order");


ha = nexttile;hold on;
ha.XLim = [-0.2, 1.2];
ha.YLim = [-0.2, 1.2];
drawnow;
hatch([0 1 1 0], [0 0 1 1], Angle=0);
hatch([0 1 1], [0 0 1], Angle=90);
title("Different Data Aspect Ratio");

%% Example 10, a patch with a hole
figure(name="Example 10 - Patch with Hole")
ha = axes;hold on;
title("Example 10 - Region with a Hole")
subtitle("Even-Odd shading can be used to create a hole in a patch")
axis equal;
ha.XLim = [-1.2, 1.2];
ha.YLim = [-1.2, 1.2];

theta = linspace(0, 360, 361);
x = [-1, 1, 1, -1, nan, ...
    0.5*cosd(theta),nan, ...
    0.2*cosd(theta)+0.7,nan, ...
    0.2*cosd(theta)-0.7,nan, ...
    0.2*cosd(theta)-0.7,nan, ...
    0.2*cosd(theta)+0.7];
y = [-1, -1, 1, 1, nan, ...
    0.5*sind(theta),nan,...
    0.2*sind(theta)+0.7,nan,...
    0.2*sind(theta)+0.7,nan,...
    0.2*sind(theta)-0.7,nan,...
    0.2*sind(theta)-0.7];
hatch(x, y);

%% Example 11, a patch with a hole
figure(name="Example 11 - Patch Holes Crossing Boundary")
ha = axes;hold on;
title("Example 11 - Patch with Holes Crossing Boundary")
subtitle("Even-Odd shading will remove overlapping regions")
axis equal;
ha.XLim = [-1.5, 1.5];
ha.YLim = [-1.5, 1.5];

theta = linspace(0, 360, 361);
x = [-1, 1, 1, -1, nan, ...
    0.5*cosd(theta),nan, ...
    0.3*cosd(theta)+1,nan, ...
    0.3*cosd(theta)-1,nan, ...
    0.3*cosd(theta)-1,nan, ...
    0.3*cosd(theta)+1];
y = [-1, -1, 1, 1, nan, ...
    0.5*sind(theta),nan,...
    0.3*sind(theta)+1,nan,...
    0.3*sind(theta)+1,nan,...
    0.3*sind(theta)-1,nan,...
    0.3*sind(theta)-1];
hatch(x, y, Angle=-30);

%% Example 12, Nested Holes
figure(name="Example 12 - Nested Holes")
ha = axes;hold on;
title("Example 11 - Patch with Holes Crossing Boundary")
subtitle("Even-Odd shading will remove overlapping regions")
axis equal;
ha.XLim = [-1.2, 1.2];
ha.YLim = [-1.2, 1.2];

theta = [linspace(0, 360, 361), nan];
x = reshape((1.0:-0.1:0.1).*cosd(theta'), 1, []);
y = reshape((1.0:-0.1:0.1).*sind(theta'), 1, []);
hatch(x, y, Spacing=8);