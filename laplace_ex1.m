function laplace_ex1()
% LAPLACE_EX1  Demonstrate Laplace interpolation on MATLAB's peppers image.
%
%   Loads peppers.png (bundled with MATLAB), randomly removes 25% of pixels,
%   reconstructs the missing values using LAPLACE, and displays a three-panel
%   comparison figure alongside PSNR and RMSE quality metrics.
%
%   The same pixel positions are masked across all three RGB channels so that
%   colour integrity is preserved.  Each channel is interpolated independently.
%
%   See also: laplace

% -------------------------------------------------------------------------
% 1. Load image
% -------------------------------------------------------------------------
img  = imread('peppers.png');   % uint8 RGB, 384 x 512 x 3
imgD = im2double(img);          % convert to double [0, 1]

[nRows, nCols, nChan] = size(imgD);
nPixels = nRows * nCols;

% -------------------------------------------------------------------------
% 2. Generate a reproducible 25% missing-pixel mask
%    (same spatial locations removed from every channel)
% -------------------------------------------------------------------------
rng(42);
missingFrac = 0.25;
nMissing    = round(missingFrac * nPixels);
missingIdx  = randperm(nPixels, nMissing);   % linear indices into one channel

fprintf('Image size : %d x %d x %d\n', nRows, nCols, nChan);
fprintf('Missing pixels : %d / %d  (%.0f%%)\n\n', nMissing, nPixels, missingFrac*100);

% -------------------------------------------------------------------------
% 3. Apply mask — set missing locations to NaN
% -------------------------------------------------------------------------
imgNaN = imgD;
for c = 1:nChan
    ch = imgNaN(:,:,c);
    ch(missingIdx) = NaN;
    imgNaN(:,:,c)  = ch;
end

% -------------------------------------------------------------------------
% 4. Laplace interpolation — process each channel independently
% -------------------------------------------------------------------------
imgFilled = zeros(nRows, nCols, nChan);

for c = 1:nChan
    fprintf('  Interpolating channel %d / %d ...\n', c, nChan);
    imgFilled(:,:,c) = laplace(imgNaN(:,:,c));
end
fprintf('\n');

% Clamp to [0,1] to guard against minor numerical overshoot at boundaries
imgFilled = max(0, min(1, imgFilled));

% -------------------------------------------------------------------------
% 5. Quality metrics
% -------------------------------------------------------------------------
% PSNR over the full image (manual — avoids Image Processing Toolbox dependency)
mse_val  = mean((imgFilled(:) - imgD(:)).^2);
psnr_val = 10 * log10(1 / mse_val);

% RMSE computed only over the pixels that were actually missing
missingMask3D = repmat(false(nRows, nCols), [1, 1, nChan]);
for c = 1:nChan
    m = false(nRows, nCols);
    m(missingIdx) = true;
    missingMask3D(:,:,c) = m;
end
diff_missing = imgFilled(missingMask3D) - imgD(missingMask3D);
rmse_val = sqrt(mean(diff_missing .^ 2));

fprintf('Quality metrics\n');
fprintf('  PSNR (full image)        : %6.2f dB\n', psnr_val);
fprintf('  RMSE (missing pixels)    : %8.4f\n',    rmse_val);

% -------------------------------------------------------------------------
% 6. Build a "damage visualisation" — mark missing pixels as mid-grey
% -------------------------------------------------------------------------
imgDamaged = imgD;
for c = 1:nChan
    ch = imgDamaged(:,:,c);
    ch(missingIdx) = 0.5;
    imgDamaged(:,:,c) = ch;
end

% -------------------------------------------------------------------------
% 7. Comparison figure
% -------------------------------------------------------------------------
figure('Name',     'Laplace Interpolation — peppers.png', ...
       'Color',    [0.12 0.12 0.15], ...   % dark background
       'Position', [60 80 1260 460]);

panelData = { ...
    imgD,       'Original', ''; ...
    imgDamaged, sprintf('Damaged  —  %.0f%% pixels missing\n(shown as mid-grey)', missingFrac*100), ''; ...
    imgFilled,  'Laplace Reconstruction', sprintf('PSNR = %.1f dB   |   RMSE = %.4f', psnr_val, rmse_val)};

for k = 1:3
    ax = subplot(1, 3, k);

    imshow(panelData{k,1}, 'Parent', ax);

    % Main panel title
    t = title(ax, panelData{k,2}, ...
              'Color', [0.92 0.92 0.92], ...
              'FontSize', 12, 'FontWeight', 'bold', ...
              'Interpreter', 'none');

    % Subtitle / metric line (only for reconstruction panel)
    if ~isempty(panelData{k,3})
        subtitle_str = panelData{k,3};
        xlabel(ax, subtitle_str, ...
               'Color', [0.65 0.85 0.65], ...   % soft green for metrics
               'FontSize', 10, 'FontWeight', 'normal', ...
               'Interpreter', 'none');
    end

    % Subtle border around each panel
    ax.XColor = [0.4 0.4 0.45];
    ax.YColor = [0.4 0.4 0.45];
    ax.LineWidth = 1;
end

sgtitle('Laplace Interpolation Demo  —  peppers.png', ...
        'Color', [0.95 0.95 0.95], ...
        'FontSize', 15, 'FontWeight', 'bold');

end
