function [xv, yv] = segments(x, y)
% segments return individual line segments from polyline
%
% xv = segments(x)
% [xv, yv] = segments(x, y)

xv = [x(1:end-1); x(2:end)];
if nargin > 1
    yv = [y(1:end-1); y(2:end)];
end