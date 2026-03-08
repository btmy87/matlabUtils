%% hatch_ex.m  —  Examples for the hatch() function
%
%   Demonstrates usage from basic calls through more advanced options.
%   Run each section (Ctrl+Enter) or the whole script at once.

%% Example 1: Basic usage — square with default hatch settings
%   45-degree hatch, 8pt spacing, black lines, no fill.
figure('Name', 'Example 1 — Basic');
hatch([0 1 1 0], [0 0 1 1]);
axis equal;
title('Basic usage — defaults (45°, 8 pt)');

%% Example 2: Change angle and spacing
%   30-degree hatch at 12pt spacing.
figure('Name', 'Example 2 — Angle & Spacing');
hatch([0 1 1 0], [0 0 1 1], Angle=30, Spacing=12);
axis equal;
title('Angle = 30°, Spacing = 12 pt');

%% Example 3: Specify a polygon face color (positional)
%   Passing a third positional argument sets the face color behind the
%   hatch lines (equivalent to FaceColor).
figure('Name', 'Example 3 — Face color (positional)');
hatch([0 1 0.5], [0 0 1], [0.7 0.85 1]);
axis equal;
title('Triangle with light-blue face');

%% Example 4: Fine hatching with custom line color
%   Dense, red hatching at a shallow angle.
figure('Name', 'Example 4 — Custom line color');
hatch([0 1 1 0], [0 0 1 1], LineColor='r', Spacing=4, Angle=15);
axis equal;
title('Dense red hatching, 15°, 4 pt');

%% Example 5: Cross-hatch by layering two hatch calls
%   Combine two hatch objects on the same axes for a cross-hatch effect.
figure('Name', 'Example 5 — Cross-hatch');
ax = gca();
hatch(ax, [0 1 1 0], [0 0 1 1], Angle=45,  Spacing=10, LineColor='k');
hatch(ax, [0 1 1 0], [0 0 1 1], Angle=-45, Spacing=10, LineColor='k');
axis(ax, 'equal');
title(ax, 'Cross-hatch (two layers)');

%% Example 6: Hatch over a solid background with custom edge
%   FaceColor gives the polygon a solid fill; the hatch lines are drawn
%   on top.  EdgeColor and LineColor are set independently.
figure('Name', 'Example 6 — Solid fill + hatch');
hatch([0 1 1 0], [0 0 1 1], ...
    FaceColor=[0.9 0.95 1], ...
    FaceAlpha=1, ...
    Angle=60, ...
    Spacing=8, ...
    LineColor=[0 0.4 0.8], ...
    LineWidth=1, ...
    EdgeColor=[0 0 0.5]);
axis equal;
title('Solid fill + blue hatching');

%% Example 7: Non-rectangular polygon on a shared axes
%   Hatch a pentagon alongside a unit-square patch to show clipping.
figure('Name', 'Example 7 — Non-rectangular polygon');
ax = gca();

% Background reference square
patch(ax, [0 1 1 0], [0 0 1 1], [0.95 0.95 0.95], EdgeColor='none');

% Pentagon
theta = (90:72:90+360-72) * pi/180;
px = 0.5 + 0.45 * cos(theta);
py = 0.5 + 0.45 * sin(theta);
hatch(ax, px, py, FaceColor=[0.8 1 0.8], FaceAlpha=0.5, ...
    Angle=45, Spacing=7, LineColor=[0 0.5 0]);

axis(ax, 'equal');
xlim(ax, [-0.1 1.1]);
ylim(ax, [-0.1 1.1]);
title(ax, 'Pentagon with green hatch');

%% Example 8: Self-intersecting polygon — pentagram (5-pointed star)
%   The vertices are ordered to trace the star outline by connecting every
%   other point of a regular pentagon.  This produces 5 edge crossings,
%   creating a self-intersecting polygon.  The even-odd inside test used
%   internally means only the five outer triangular points are hatched,
%   not the central pentagonal region (which winds twice).
figure('Name', 'Example 8 — Self-intersecting pentagram');
ax = gca();

% Build pentagram vertex sequence: skip every other tip of a circle
nPts     = 5;
tipAngle = (90 : -360/nPts : 90 - 360 + 360/nPts) * pi/180;
tipOrder = mod((0 : nPts-1) * 2, nPts) + 1;   % connect every 2nd tip
starX    = cos(tipAngle(tipOrder));
starY    = sin(tipAngle(tipOrder));

hatch(ax, starX, starY, ...
    FaceColor=[1 0.95 0.8], ...
    FaceAlpha=1, ...
    Angle=45, ...
    Spacing=7, ...
    LineColor=[0.7 0.4 0], ...
    LineWidth=0.75, ...
    EdgeColor='k');

axis(ax, 'equal');
axis(ax, 'off');
title(ax, 'Self-intersecting pentagram (even-odd hatching)');
