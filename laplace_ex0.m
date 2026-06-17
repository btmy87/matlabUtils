%% laplace_ex0
% example use of laplace function

%% Example 1 — sin/cos surface with a rectangular missing block
% Punch a hole in a smooth surface and recover it
[X, Y] = meshgrid(linspace(0,1,40));
Z_orig = sin(pi*X) .* cos(pi*Y);   % original (no NaNs)
Z = Z_orig;
Z(15:25, 15:25) = NaN;             % remove a block
Z_filled = laplace(Z);

figure;
ax1(1) = subplot(1,3,1); surf(X, Y, Z_orig,   'EdgeColor','none'); title('Original');
ax1(2) = subplot(1,3,2); surf(X, Y, Z,        'EdgeColor','none'); title('Input (with NaNs)');
ax1(3) = subplot(1,3,3); surf(X, Y, Z_filled, 'EdgeColor','none'); title('Laplace interpolation');
colormap parula;
Link1 = linkprop(ax1, {'CameraPosition','CameraTarget','CameraUpVector','CameraViewAngle'});
setappdata(gcf, 'StoreLink', Link1);   % keep link alive for figure lifetime

%% Example 2 — peaks surface with a rectangular missing block
% Use the built-in peaks function to generate a more complex test surface,
% then recover a missing rectangular block using Laplace interpolation.

Z2_orig = peaks(100);              % 100x100 smooth multi-peak surface (original)
[X2, Y2] = meshgrid(1:100);
Z2 = Z2_orig;
Z2(38:63, 38:63) = NaN;           % punch out a block (proportional to 15:25 on 40-pt grid)
Z2_filled = laplace(Z2);

figure;
ax2(1) = subplot(1,3,1); surf(X2, Y2, Z2_orig  , EdgeColor="k"); title('Original');
ax2(2) = subplot(1,3,2); surf(X2, Y2, Z2       , EdgeColor="k"); title('peaks input (with NaNs)');
ax2(3) = subplot(1,3,3); surf(X2, Y2, Z2_filled, EdgeColor="k"); title('Laplace interpolation');
colormap parula;
Link2 = linkprop(ax2, {'CameraPosition','CameraTarget','CameraUpVector','CameraViewAngle'});
setappdata(gcf, 'StoreLink', Link2);   % keep link alive for figure lifetime