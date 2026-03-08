function h = hatch(varargin)
% hatch  Draw a polygon filled with hatch lines.
%
%   Syntax:
%       h = hatch(x, y)
%       h = hatch(x, y, c)
%       h = hatch(ax, x, y)
%       h = hatch(ax, x, y, c)
%       h = hatch(___, Name=Value)
%
%   Description:
%       hatch draws a polygon defined by vertices (x, y) and fills the
%       interior with parallel hatch lines.  The polygon outline is drawn
%       using a patch object.  The hatch lines are redrawn automatically
%       when the figure is resized or the axes limits change, so that the
%       line spacing stays constant in physical screen units (points).
%
%   Inputs:
%       ax      - Target axes (default: gca)
%       x       - x-coordinates of polygon vertices (numeric vector)
%       y       - y-coordinates of polygon vertices (numeric vector)
%       c       - Polygon face color (default: 'none')
%
%   Name-Value Arguments:
%       Spacing   (default 8)     - Hatch line spacing in points
%                                   (1 pt = 1/72 inch)
%       Angle     (default 45)    - Hatch line angle in degrees from
%                                   horizontal
%       LineColor (default 'k')   - Hatch line color
%       LineWidth (default 0.5)   - Hatch line width in points
%       EdgeColor (default 'k')   - Polygon outline color
%       FaceAlpha (default 0)     - Polygon face transparency [0, 1]
%       FaceColor (default 'none')- Polygon background fill color
%
%   Output:
%       h       - hggroup handle containing the patch and line objects.
%                 The patch handle is stored in h.UserData.patch and the
%                 most recent hatch line object in h.UserData.lines.
%
%   Example:
%       figure;
%       hatch([0 1 1 0], [0 0 1 1]);
%
%       figure;
%       hatch([0 1 0.5], [0 0 1], 'b', Spacing=12, Angle=30);
%
%   See also: patch, fill

%% Separate raw positional args from Name-Value pairs
% Named parameter keys accepted by this function
nvKeys = {'Spacing', 'Angle', 'LineColor', 'LineWidth', ...
    'EdgeColor', 'FaceAlpha', 'FaceColor'};

% Walk varargin to find where positional args end and NV pairs begin.
% Positional slots: [ax?], x, y, [c]
posArgs = {};
nvArgs  = {};
k = 1;
while k <= numel(varargin)
    v = varargin{k};
    posCount = numel(posArgs);

    if posCount < 4 && ~isNVKey(v, nvKeys)
        % Still collecting positional arguments
        posArgs{end+1} = v; %#ok<AGROW>
        k = k + 1;
    else
        % Remainder is Name-Value pairs
        nvArgs = varargin(k:end);
        break;
    end
end

%% Identify leading axes argument
argIdx = 1;
if ~isempty(posArgs) && isscalar(posArgs{argIdx}) && ...
        isa(posArgs{argIdx}, 'matlab.graphics.axis.AbstractAxes')
    ax = posArgs{argIdx};
    argIdx = argIdx + 1;
else
    ax = gca();
end

%% Extract x, y, and optional face color from remaining positional args
if argIdx > numel(posArgs)
    error('hatch:invalidInput', ...
        'hatch requires at least x and y vertex coordinates.');
end
x = posArgs{argIdx};    argIdx = argIdx + 1;

if argIdx > numel(posArgs)
    error('hatch:invalidInput', ...
        'hatch requires at least x and y vertex coordinates.');
end
y = posArgs{argIdx};    argIdx = argIdx + 1;

if argIdx <= numel(posArgs)
    faceColorPos = posArgs{argIdx};
else
    faceColorPos = 'none';
end

%% Parse Name-Value pairs
p = inputParser();
p.addParameter('Spacing',   8,             @(v) isnumeric(v) && isscalar(v) && v > 0);
p.addParameter('Angle',     45,            @(v) isnumeric(v) && isscalar(v));
p.addParameter('LineColor', 'k',           @isValidColor);
p.addParameter('LineWidth', 0.5,           @(v) isnumeric(v) && isscalar(v) && v > 0);
p.addParameter('EdgeColor', 'k',           @isValidColor);
p.addParameter('FaceAlpha', 0,             @(v) isnumeric(v) && isscalar(v));
p.addParameter('FaceColor', faceColorPos,  @isValidColor);
p.parse(nvArgs{:});
opts = p.Results;

% Positional color arg is overridden by explicit Name-Value FaceColor
if ismember('FaceColor', p.UsingDefaults)
    opts.FaceColor = faceColorPos;
end

%% Create hggroup to hold all graphics objects
hg = hggroup(ax);

%% Draw the polygon outline with patch
patchHandle = patch(ax, ...
    'XData',      x(:), ...
    'YData',      y(:), ...
    'FaceColor',  opts.FaceColor, ...
    'FaceAlpha',  opts.FaceAlpha, ...
    'EdgeColor',  opts.EdgeColor, ...
    'Parent',     hg);

%% Store state needed to redraw hatch lines
hg.UserData.patch     = patchHandle;
hg.UserData.lines     = gobjects(0);
hg.UserData.x         = x(:);
hg.UserData.y         = y(:);
hg.UserData.spacing   = opts.Spacing;
hg.UserData.angle     = opts.Angle;
hg.UserData.lineColor = opts.LineColor;
hg.UserData.lineWidth = opts.LineWidth;

%% Draw initial hatch lines
drawHatchLines(hg, ax);

%% Attach listeners for auto-redraw on zoom / pan / resize
fig = ancestor(ax, 'figure');

limListener = addlistener(ax, {'XLim', 'YLim', 'Position'}, ...
    'PostSet', @(~, ~) drawHatchLines(hg, ax));

resizeListener = addlistener(fig, 'SizeChanged', ...
    @(~, ~) drawHatchLines(hg, ax));

% Clean up listeners when the hggroup is deleted
addlistener(hg, 'ObjectBeingDestroyed', @(~, ~) deleteListeners());

    function deleteListeners()
        delete(limListener);
        delete(resizeListener);
    end

h = hg;

end

%% -----------------------------------------------------------------------
function tf = isNVKey(v, keys)
% isNVKey  Return true when v looks like a Name-Value parameter name.
tf = (ischar(v) || (isstring(v) && isscalar(v))) && ...
    any(strcmpi(v, keys));
end

%% -----------------------------------------------------------------------
function tf = isValidColor(v)
% isValidColor  Validate a color spec (short name, long name, or RGB triple).
tf = ischar(v) || isstring(v) || (isnumeric(v) && isvector(v) && numel(v) == 3);
end

%% -----------------------------------------------------------------------
function drawHatchLines(hg, ax)
% drawHatchLines  Recompute and redraw hatch lines inside the polygon.

if ~isvalid(hg) || ~isvalid(ax)
    return;
end

% Delete old hatch line objects
if isfield(hg.UserData, 'lines') && ~isempty(hg.UserData.lines)
    delete(hg.UserData.lines(isvalid(hg.UserData.lines)));
    hg.UserData.lines = gobjects(0);
end

x          = hg.UserData.x;
y          = hg.UserData.y;
spacingPt  = hg.UserData.spacing;
angleDeg   = hg.UserData.angle;
lineColor  = hg.UserData.lineColor;
lineWidth  = hg.UserData.lineWidth;

%% Convert spacing from points to pixels
screenDpi = get(0, 'ScreenPixelsPerInch');
ptPerInch = 72;
spacingPx = spacingPt * (screenDpi / ptPerInch);

%% Get axes extent in pixels and compute data-to-pixel transforms
axPosPx    = getpixelposition(ax);
axWidthPx  = axPosPx(3);
axHeightPx = axPosPx(4);

if axWidthPx <= 0 || axHeightPx <= 0
    return;
end

xLim   = ax.XLim;
yLim   = ax.YLim;
xScale = axWidthPx  / (xLim(2) - xLim(1));   % pixels per data unit
yScale = axHeightPx / (yLim(2) - yLim(1));

    function px = data2px(xd, yd)
        px = [(xd - xLim(1)) * xScale, (yd - yLim(1)) * yScale];
    end

    function [xd, yd] = px2data(px)
        xd = px(:, 1) / xScale + xLim(1);
        yd = px(:, 2) / yScale + yLim(1);
    end

%% Convert polygon vertices to pixel space
polyPx = data2px(x, y);

%% Generate hatch line segments in pixel space
% Bounding box of the polygon (pixel space), with padding
bbox    = [min(polyPx(:, 1)), min(polyPx(:, 2)); ...
    max(polyPx(:, 1)), max(polyPx(:, 2))];
diagLen = norm(bbox(2, :) - bbox(1, :)) + 2 * spacingPx;
center  = mean(bbox, 1);

angleRad = deg2rad(angleDeg);
along    = [ cos(angleRad),  sin(angleRad)];   % unit vector along lines
perp     = [-sin(angleRad),  cos(angleRad)];   % unit vector perpendicular

offsets = (-diagLen : spacingPx : diagLen);

% Accumulate clipped segments using a cell array to support a variable
% number of interior sub-segments per hatch line (needed for
% self-intersecting polygons where one line may enter/exit multiple times).
segCellX = cell(numel(offsets), 1);
segCellY = cell(numel(offsets), 1);

for k = 1:numel(offsets)
    % Line through (center + offset*perp), direction = along
    p0 = center + offsets(k) * perp;
    p1 = p0 - diagLen * along;
    p2 = p0 + diagLen * along;

    [cx, cy] = clipLineToPoly([p1; p2], polyPx);
    segCellX{k} = cx;
    segCellY{k} = cy;
end

xSegs = [segCellX{:}];
ySegs = [segCellY{:}];

if isempty(xSegs)
    return;
end

%% Convert clipped segments back to data coordinates and draw
[xData, yData] = px2data([xSegs(:), ySegs(:)]);

lh = line(ax, xData, yData, ...
    'Color',         lineColor, ...
    'LineWidth',     lineWidth, ...
    'Parent',        hg, ...
    'HitTest',       'off', ...
    'PickableParts', 'none');

hg.UserData.lines = lh;

end

%% -----------------------------------------------------------------------
function [cx, cy] = clipLineToPoly(seg, poly)
% clipLineToPoly  Clip a line to all interior segments of a polygon.
%
%   Handles convex, concave, and self-intersecting polygons by testing
%   every consecutive pair of edge-intersection parameters independently
%   with an even-odd inside test.  Each valid interior sub-segment is
%   appended to cx/cy separated by NaN.
%
%   seg  - 2-by-2 matrix [x1 y1; x2 y2] (line endpoints in pixel space)
%   poly - N-by-2 matrix of polygon vertices (pixel space)
%
%   Returns cx, cy as row vectors with NaN separators between segments,
%   or empty arrays if the line does not intersect the polygon interior.

cx = [];
cy = [];

p1 = seg(1, :);
p2 = seg(2, :);

n = size(poly, 1);

% Close polygon
polyX = [poly(:, 1); poly(1, 1)];
polyY = [poly(:, 2); poly(1, 2)];

d = p2 - p1;   % direction vector of the test line

% Collect parameter values t where line p1 + t*d crosses each edge
tVals = zeros(1, 2 * n);
nHits = 0;

for k = 1:n
    e1 = [polyX(k),   polyY(k)  ];
    e2 = [polyX(k+1), polyY(k+1)];
    ev = e2 - e1;

    denom = d(1) * ev(2) - d(2) * ev(1);

    if abs(denom) < eps
        continue;   % parallel edge — skip
    end

    w = e1 - p1;
    t = (w(1) * ev(2) - w(2) * ev(1)) / denom;   % param on test line
    s = (w(1) * d(2)  - w(2) * d(1))  / denom;   % param on edge [0,1]

    if s >= 0.0 && s <= 1.0
        nHits = nHits + 1;
        tVals(nHits) = t;
    end
end

if nHits < 2
    return;
end

% Sort and deduplicate (near-coincident intersections from shared vertices)
tVals = uniquetol(sort(tVals(1:nHits)), 1e-9);

% Test every consecutive pair of intersections independently.
% A self-intersecting polygon can produce multiple disjoint interior spans
% along a single hatch line (e.g., two tips of a star).
for k = 1:numel(tVals)-1
    tMid  = 0.5 * (tVals(k) + tVals(k+1));
    midPt = p1 + tMid * d;

    if isInsidePoly(midPt(1), midPt(2), poly(:, 1), poly(:, 2))
        pt1 = p1 + tVals(k)   * d;
        pt2 = p1 + tVals(k+1) * d;
        cx  = [cx,  pt1(1), pt2(1), NaN]; %#ok<AGROW>
        cy  = [cy,  pt1(2), pt2(2), NaN]; %#ok<AGROW>
    end
end

end

%% -----------------------------------------------------------------------
function inside = isInsidePoly(px, py, polyX, polyY)
% isInsidePoly  Ray-casting even-odd point-in-polygon test.

n      = numel(polyX);
inside = false;
j      = n;

for i = 1:n
    xi = polyX(i);  yi = polyY(i);
    xj = polyX(j);  yj = polyY(j);

    if ((yi > py) ~= (yj > py)) && ...
            (px < (xj - xi) * (py - yi) / (yj - yi) + xi)
        inside = ~inside;
    end
    j = i;
end

end
