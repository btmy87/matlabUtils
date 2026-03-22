function [h, xplot, yplot] = hatchline(x, y, opts)

arguments
    x (1, :) double
    y (1, :) double
    opts.Parent = gca;
    opts.Angle (1, 1) double = 45;
    opts.Spacing (1, 1) double = 8;
    opts.Length (1, 1) double = 12;
    opts.PlotBounds (1, 1) {mustBeNumericOrLogical} = true;
    opts.Plot (1, 1) {mustBeNumericOrLogical} = true;
    opts.Method (1, 1) string {mustBeMember(opts.Method, ["Absolute", "Relative"])} = "Absolute"
    opts.RelTol (1, 1) double {mustBePositive} = 1e-10; % used for self-intersection check

    opts.Color = [];    
    opts.DisplayName (1, 1) string = "";
    opts.LineWidth (1, 1) double = get(gca, 'DefaultLineLineWidth');
    opts.LineStyle (1, 1) string = get(gca, 'DefaultLineLineStyle');
    opts.Marker (1, 1) string = get(gca, 'DefaultLineMarker');
    opts.MarkerSize (1, 1) double = get(gca, 'DefaultLineMarkerSize');
end

assert(ndims(x) == ndims(y) && all(size(x)==size(y)), ...
    "x and y arrays must be the same size\n");

if isempty(opts.Color)
    opts.Color = opts.Parent.ColorOrder(opts.Parent.ColorOrderIndex, :);
end

% force parent to draw so we have screen coordinates, use a dummy patch
% object to force axes limits if they haven't already been locked
if string(opts.Parent.XLimMode) == "auto" || string(opts.Parent.YLimMode) == "auto"
    htemp = plot(opts.Parent, x, y);
    drawnow;
    delete(htemp);

    % revert cycling of color order index
    opts.Parent.ColorOrderIndex = mod(opts.Parent.ColorOrderIndex - 2, size(opts.Parent.ColorOrder, 1)) + 1;

    opts.Parent.XLim = opts.Parent.XLim; % fix axes
    opts.Parent.YLim = opts.Parent.YLim;
end

% convert x and y to screen coordinates
[xs, ys, scaleX, scaleY] = data_to_screen(x, y, opts.Parent);

if opts.Method == "Absolute"
    % create a polygon by offsetting 
    xoffset = opts.Length.*cosd(opts.Angle);
    yoffset = opts.Length.*sind(opts.Angle);

    xpolys = [xs, fliplr(xs)+xoffset, xs(1)];
    ypolys = [ys, fliplr(ys)+yoffset, ys(1)];

    % convert back to data coords
    [xpoly, ypoly] = screen_to_data(xpolys, ypolys, scaleX, scaleY);

    % generate hatch lines without bounds
    opts2 = rmfield(opts, ["Length", "Method", "RelTol"]);
    opts2.PlotBounds = false;
    opts2.Plot = false;
    nvPairs = namedargs2cell(opts2);
    [~, xplot, yplot] = hatch(xpoly, ypoly, nvPairs{:});

    [h, xplot, yplot] = plot_hatch(x, y, xplot, yplot, opts);
    
else
    % opts.Method == relative

    % parameterize curve as a function of arc-length
    [tmax, fx, fy, fa] = parameterize(xs, ys);

    % make tick marks
    [xhs, yhs] = make_ticks(tmax, fx, fy, fa, opts.Angle, opts.Length, opts.Spacing);

    % check for self-intersections
    [xhs2, yhs2] = clip_to_line(xs, ys, xhs, yhs, opts.RelTol);

    % convert back to data coordinates
    [xh, yh] = screen_to_data(xhs2, yhs2, scaleX, scaleY);

    % plot
    [h, xplot, yplot] = plot_hatch(x, y, xh, yh, opts);

end

end

function [xs, ys, scaleX, scaleY] = data_to_screen(x, y, ha)
% convert data coordiantes to screen coordinates in inches

POINTS_PER_INCH = 72;
DPI = get(groot, "ScreenPixelsPerInch");

dataWidth = ha.XLim(2) - ha.XLim(1);
dataHeight = ha.YLim(2) - ha.YLim(1);
pos = getpixelposition(ha)./DPI.*POINTS_PER_INCH;
screenWidth = pos(3);
screenHeight = pos(4);

% inferred aspect raito from pixelposition doesn't match what's actually on
% screen.  Actual display aligns with PlotBoxAspectRatio.  This correction
% seems to work
scaleX = screenWidth./dataWidth;
scaleY = screenHeight./dataHeight ...
       .* ha.PlotBoxAspectRatio(2)./ha.PlotBoxAspectRatio(1) ...
       .* screenWidth./screenHeight;
xs = x.*scaleX;
ys = y.*scaleY;


end

function [x, y] = screen_to_data(xs, ys, scaleX, scaleY)
% convert screen coordinates back to data coordinates
x = xs./scaleX;
y = ys./scaleY;
end

function [h, xplot, yplot] = plot_hatch(xc, yc, xh, yh, opts)
% plot hatch and optionally bounds as a single line

if opts.PlotBounds
    xplot = [xc, nan, xh];
    yplot = [yc, nan, yh];
else
    xplot = xh;
    yplot = yh;
end

if opts.Plot
    h = plot(opts.Parent, xplot, yplot, ...
           LineStyle=opts.LineStyle, ...
           Color=opts.Color, ...
           LineWidth=opts.LineWidth, ...
           DisplayName=opts.DisplayName, ...
           Marker=opts.Marker, ...
           MarkerSize=opts.MarkerSize);
else
    h = [];
end

end

function [tmax, fx, fy, fa] = parameterize(xs, ys)
% parameterize curve as a function of arc length

dx = diff(xs);
dy = diff(ys);
ds = sqrt(dx.^2+dy.^2);
theta = atan2d(dy, dx);
t = [0, cumsum(ds)];

fx = griddedInterpolant(t, xs);
fy = griddedInterpolant(t, ys);
tmax = t(end);

% make angle interpolant
ta = [t(1), ...
      reshape([t(2:end-1);t(2:end-1)+eps(t(2:end-1))], 1, []), ...
      t(end)];
theta2 = reshape([theta; theta], 1, []);
fa = griddedInterpolant(ta, theta2);
end


function [xh, yh] = make_ticks(tmax, fx, fy, fa, theta, L, spacing)
% make tick marks

t = 0:spacing:tmax;
xh(1, :) = fx(t);
yh(1, :) = fy(t);

alpha = fa(t);
xh(2, :) = xh(1, :) + L*cosd(theta+alpha);
yh(2, :) = yh(1, :) + L*sind(theta+alpha);


end

function [xp, yp] = clip_to_line(xs, ys, xhs, yhs, tol)
% if tic line crosses through original line, clip

[xi, yi, ~, ti] = line_intersect(segments(xs), segments(ys), xhs, yhs);

tol = max(max(xs)-min(xs), max(ys)-min(ys))*tol;
for i = 1:size(xhs, 2)
    t = ti(:, i);
    t1 = t(isfinite(t));
    x1 = xi(isfinite(t), i);
    y1 = yi(isfinite(t), i);
    
    % omit the cases where t1==0, the start point should be on the line
    % doesn't handle case where the base curve tracks back on itself.
    idx = find(t1<tol);
    t1(idx) = [];
    x1(idx) = [];
    y1(idx) = [];

    % if t1 is non-empty, we have an intersection to clip to
    if ~isempty(t1)
        % clip to xi and yi with the lowest ti parameter
        [~, idx] = min(t1);
        xhs(2, i) = x1(idx);
        yhs(2, i) = y1(idx);
    end
end

% reshape so they're 1D vectors separated by nan's
xp = reshape([xhs; nan(1, size(xhs, 2))], 1, []);
yp = reshape([yhs; nan(1, size(xhs, 2))], 1, []);
end