function [h, xplot, yplot] = hatch(x, y, opts)

arguments
    x (1, :) double
    y (1, :) double
    opts.Parent = gca;
    opts.Angle (1, 1) double = 45;
    opts.Spacing (1, 1) double = 0.2;
    opts.PlotBounds (1, 1) {mustBeNumericOrLogical} = true;
    opts.Plot (1, 1) {mustBeNumericOrLogical} = true;

    opts.Color = [];    
    opts.DisplayName (1, 1) string = "";
    opts.LineWidth (1, 1) double = get(gca, 'DefaultLineLineWidth');
    opts.LineStyle (1, 1) string = get(gca, 'DefaultLineLineStyle');
    opts.Marker (1, 1) string = get(gca, 'DefaultLineMarker');
    opts.MarkerSize (1, 1) double = get(gca, 'DefaultLineMarkerSize');
end

assert(ndims(x) == ndims(y) && all(size(x)==size(y)), ...
    "x and y arrays must be the same size\n");

assert(all(isnan(x) == isnan(y)), ...
    "Segment pattern (nan's) must match between x and y");

if isempty(opts.Color)
    opts.Color = opts.Parent.ColorOrder(opts.Parent.ColorOrderIndex, :);
end

% force parent to draw so we have screen coordinates, use a dummy patch
% object to force axes limits if they haven't already been locked
if string(opts.Parent.XLimMode) == "auto" || string(opts.Parent.YLimMode) == "auto"
    hpatch = patch(opts.Parent, 'XData', x, 'YData', y);
    drawnow;
    delete(hpatch);
    opts.Parent.XLim = opts.Parent.XLim; % fix axes
    opts.Parent.YLim = opts.Parent.YLim;
end

% close polygon if not closed
[xc, yc] = close_polygon(x, y);

% convert x and y to screen coordinates
[xs, ys, scaleX, scaleY] = data_to_screen(xc, yc, opts.Parent);

% create array of hatch lines in screen coords
[xhs, yhs] = hatch_patern(xs, ys, opts.Spacing, opts.Angle);

% trim lines to bounds
[xhst, yhst] = trim_lines(xs, ys, xhs, yhs);

% convert back to data coordinates
[xh, yh] = screen_to_data(xhst, yhst, scaleX, scaleY);

% plot hatch lines
[h, xplot, yplot] = plot_hatch(xc, yc, xh, yh, opts);

end

function [x, y] = close_polygon(x, y)
% close polygon if not already closed
% needs to close each segment if nan separated segments are found

% trim leading and force trailing nan
if isnan(x(1))
    x = x(2:end);
    y = y(2:end);
end
if ~isnan(x(end))
    x = [x, nan];
    y = [y, nan];
end

% identify indicies at the end of each segment
idx = find(isnan(x));

% close each section
for i = 1:length(idx)
    if i == 1
        iStart = 1;
    else
        iStart = idx(i-1);
    end
    iEnd = idx(i);
    if x(iStart)~=x(iEnd) || y(iStart)~=y(iEnd)
        % shift entries down and add new entry
        x = [x(1:iEnd-1),x(iStart),x(iEnd:end)];
        y = [y(1:iEnd-1),y(iStart),y(iEnd:end)];

        % update ending indices for this and later segments
        idx(i:end) = idx(i:end)+1;
    end
end

end

function [xs, ys, scaleX, scaleY] = data_to_screen(x, y, ha)
% convert data coordiantes to screen coordinates in inches

dataWidth = ha.XLim(2) - ha.XLim(1);
dataHeight = ha.YLim(2) - ha.YLim(1);
pos = getpixelposition(ha)./get(groot, "ScreenPixelsPerInch");
screenWidth = pos(3);
screenHeight = pos(4);

scaleX = screenWidth/dataWidth;
scaleY = screenHeight./dataHeight;
xs = x.*scaleX;
ys = y.*scaleY;

end

function [x, y] = screen_to_data(xs, ys, scaleX, scaleY)
% convert screen coordinates back to data coordinates
x = xs./scaleX;
y = ys./scaleY;
end

function [xhs, yhs] = hatch_patern(xs, ys, spacing, theta)
% create hatch lines filling a bounding box

% find bounding box of xs and ys
boundLeft = min(xs, [], "omitnan");
boundRight = max(xs, [], "omitnan");
boundTop = max(ys, [], "omitnan");
boundBottom = min(ys, [], "omitnan");

% imagine a line through the center of our bounding box and orthoganal to
% the hatch lines.
% consider a line of the form below, solve for the parameter "t" values
% where it intersects the bounding box
%   x = x0 + t*cos(theta)
%   y = y0 + t*sin(theta)
alpha = theta + 90;
x0 = 0.5*(boundLeft + boundRight);
y0 = 0.5*(boundTop + boundBottom);
t(1) = (boundRight - x0)./cosd(alpha);
t(2) = (boundLeft - x0)./cosd(alpha);
t(3) = (boundTop - y0)./sind(alpha);
t(4) = (boundBottom - y0)./sind(alpha);

% select the two relevant intersections, the closest intersections in both
% the negative and positive directions
t1 = min(t(isfinite(t)));
t2 = max(t(isfinite(t)));

% create a range of reference points for our hatch lines
tref = t1:spacing:t2;
xref = x0 + tref.*cosd(alpha);
yref = y0 + tref.*sind(alpha);

% hatch lines don't need to be any longer than the bounding box diagonal in
% both directions
h = sqrt((boundRight-boundLeft).^2 + (boundTop-boundBottom).^2);

% create hatch lines, note use of array expansion
% output size will be [2, length(tref)]
xhs = [-h; h].*cosd(theta) + xref;
yhs = [-h; h].*sind(theta) + yref;

end

function [xhst, yhst] = trim_lines(xs, ys, xhs, yhs)
[xi, yi, ~, ti] = line_intersect(segments(xs), segments(ys), xhs, yhs);

xhst = [];
yhst = [];

% loop through hatch lines
for iHatch = 1:size(xi, 2)
    % find indices of intersections
    k = find(~isnan(xi(:, iHatch)));

    % find coordinates of intersections, and sort
    x = xi(k, iHatch);
    y = yi(k, iHatch);
    t = ti(k, iHatch);
    [~, isort] = sort(t);
    xsort = x(isort);
    ysort = y(isort);

    % loop through pairs of intersections and save
    for iIntersect = 1:2:length(k)
        xhst = [xhst, [xsort(iIntersect);...
                       xsort(iIntersect+1)]]; %#ok<AGROW>
        yhst = [yhst, [ysort(iIntersect);...
                       ysort(iIntersect+1)]]; %#ok<AGROW>
    end
end

end

function [h, xplot, yplot] = plot_hatch(xc, yc, xh, yh, opts)
% plot hatch and optionally bounds as a single line

% add padding nan's to hatch lines and reshape to vector
xhp = reshape([xh; nan(1, size(xh, 2))], 1, []);
yhp = reshape([yh; nan(1, size(yh, 2))], 1, []);

if opts.PlotBounds
    xplot = [xc, nan, xhp];
    yplot = [yc, nan, yhp];
else
    xplot = xhp;
    yplot = yhp;
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