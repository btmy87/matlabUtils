function [xi, yi, ta, tb] = line_intersect(xa, ya, xb, yb)
% line_intersect find line segment intersection points
% finds intersection points between two groups of line segments `a` and `b`
% returns nan if there's no intersection or segments are colinear
%
% [xi, yi] = line_intersect(xa, ya, xb, yb); Solvers for x-y coordinates
% [xi, yi, ta, tb] = line_intersect(...); Also outputs parameter values at
% intersection points.
%
% Inputs are 2xN arrays where each column is a line segment
% Groups `a` and `b` can have different numbers of line segments.
%
% Outputs, NxM arrays with intersection points.
% xi(i, j) is the x-coordinate where the i'th line in set `a` intersects
% with the j'th line in set `b`
%
% Note: this code depends on the array expansion syntax introduced in
% MatLab 2016b.  
%
% Methods:
% write the equations in parametric form
% xa = xa1 + ta*(xa2-xa1), ya = ya1 + ta*(ya2-ya1)
% xb = xb1 + tb*(xb2-xb2), yb = yb1 + tb*(yb2-yb1)
% 
% we define certain delta parameters
% dxa = xa2-xa1, dya = ya2-ya1
% dxb = xb2-xb1, dyb = yb2-yb1
% dx1 = xa1-xb1, dy1 = ya1-yb1
%
% we rearrange and solve for ta and tb

%% make sure inputs are the right shape
if size(xb, 1)~=2
    xb = reshape(xb, 2, []);
end
if size(yb, 1)~=2
    yb = reshape(yb, 2, []);
end

if size(xa, 1)~=2
    xa = reshape(xa, 2, []);
end
if size(ya, 1)~=2
    ya = reshape(ya, 2, []);
end

%% Calculate our delta terms
% note that the `a` variables are transposed to force array expansion
% outputs are all NxM arrays
dx1 = xa(1, :)'-xb(1, :);
dy1 = ya(1, :)'-yb(1, :);
dxa = xa(2, :)'-xa(1, :)';
dya = ya(2, :)'-ya(1, :)';
dxb = xb(2, :)-xb(1, :);
dyb = yb(2, :)-yb(1, :);

%% solve for parameter values at intersection
% while denominator is common, recalculating is slightly faster for large
% sets.
tb = (dx1.*dya-dy1.*dxa)./(dxb.*dya-dxa.*dyb);
ta = (dx1.*dyb-dy1.*dxb)./(dxb.*dya-dxa.*dyb);

% replace intersection values outside of segment with nan's
idx = ta<0 | ta>1 | tb<0 | tb>1;
tb(idx) = nan;

%% solve for x-y locations
xi = xb(1, :) + tb.*(xb(2, :)-xb(1, :));
yi = yb(1, :) + tb.*(yb(2, :)-yb(1, :));
