function [S,AX,BigAx,H,HAx] = plottable(tbl, xvars, yvars, ax)
% plottable calls plot matrix on table variables
% like plotmatrix, but with labels!

arguments
    tbl table
    xvars (1, :) string = string(tbl.Properties.VariableNames)
    yvars (1, :) string = strings([]);
    ax (1, 1) matlab.graphics.axis.Axes = gca;
end

assert(~isempty(tbl));

X = tbl{:, xvars};
nx = length(xvars);
ny = nx;

if isempty(yvars)
    yvars = xvars;
    [S, AX, BigAx, H, HAx] = plotmatrix(ax, X);
else
    Y = tbl{:, yvars};
    ny = length(yvars);
    [S, AX, BigAx, H, HAx] = plotmatrix(ax, X, Y);
end

% place x labels
for i = 1:nx
    xlabel(AX(ny, i), xvars(i));
end

for i = 1:ny
    ylabel(AX(i, 1), yvars(i));
end



