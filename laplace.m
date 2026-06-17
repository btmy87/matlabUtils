function Z = laplace(Z)
% LAPLACE  Fill NaN values in a 2D matrix via Laplace interpolation.
%
%   Z = LAPLACE(Z) replaces NaN entries in the 2D matrix Z by solving the
%   discrete Laplace equation on the missing-value grid:
%
%       u(i,j) = mean( u(neighbors) )
%
%   i.e. each unknown is constrained to equal the average of its four
%   axis-aligned neighbors (up / down / left / right).  Boundary pixels use
%   only the neighbors that exist inside the matrix.
%
%   All unknowns are solved simultaneously as a sparse linear system
%
%       A * x = b
%
%   so the method correctly handles regions where multiple adjacent values
%   are missing — no iterative relaxation is required.
%
%   Input:
%       Z  - 2D numeric matrix.  NaN marks unknown / missing values.
%            Non-NaN entries are treated as fixed Dirichlet boundary
%            conditions.
%
%   Output:
%       Z  - Same matrix with NaN values replaced by the Laplace solution.
%
%   Notes:
%     * If ALL entries are NaN the discrete Laplacian has no boundary
%       conditions and the linear system is singular (infinite solutions).
%       A warning is issued and Z is returned unchanged in that case.
%     * The function uses MATLAB's built-in sparse direct solver (\), which
%       is efficient even for large grids.
%
%   Example:
%       % Punch a hole in a smooth surface and recover it
%       [X, Y] = meshgrid(linspace(0,1,40));
%       Z = sin(pi*X) .* cos(pi*Y);
%       Z(15:25, 15:25) = NaN;          % remove a block
%       Z_filled = laplace(Z);
%       figure;
%       subplot(1,2,1); imagesc(Z);      title('Input (with NaNs)');
%       subplot(1,2,2); imagesc(Z_filled); title('Laplace interpolation');

% -------------------------------------------------------------------------
% 0. Validate input
% -------------------------------------------------------------------------
validateattributes(Z, {'numeric'}, {'2d'}, 'laplace', 'Z');

[nRows, nCols] = size(Z);
nanMask = isnan(Z);

% Nothing to do?
if ~any(nanMask(:))
    return;
end

% Ill-posed: no known boundary values
if all(nanMask(:))
    warning('laplace:noBoundary', ...
        'All values are NaN — the Laplace system has no boundary conditions. Z is returned unchanged.');
    return;
end

% -------------------------------------------------------------------------
% 1.  Number the unknowns 1 … M
% -------------------------------------------------------------------------
nanIdx = find(nanMask);      % linear indices of NaN pixels
M      = numel(nanIdx);

% Fast lookup: linear index in Z  -->  unknown index (0 = known pixel)
idxMap          = zeros(nRows, nCols, 'int32');
idxMap(nanIdx)  = 1:M;

% -------------------------------------------------------------------------
% 2.  Build sparse linear system  A * x = b
%
%     Equation for unknown k at grid position (i,j):
%
%       n_k * x_k  -  sum_{NaN neighbours}(x_neighbour)  =  sum_{known neighbours}(Z_neighbour)
%
%     where n_k is the number of in-bounds neighbours.
%     This is a re-arrangement of  x_k = mean(all neighbours).
% -------------------------------------------------------------------------

% Pre-allocate COO storage (at most 5 entries per unknown: 1 diagonal + 4 off-diagonal)
nnzMax = 5 * M;
rowIdx = zeros(nnzMax, 1, 'int32');
colIdx = zeros(nnzMax, 1, 'int32');
vals   = zeros(nnzMax, 1);
b      = zeros(M, 1);
ptr    = 0;

% 4-connected neighbour offsets  [row, col]
OFFSETS = int32([-1  0;   % up
                  1  0;   % down
                  0 -1;   % left
                  0  1]); % right

for k = 1:M
    [i, j]     = ind2sub([nRows, nCols], nanIdx(k));
    nNeighbours = 0;

    for d = 1:4
        ni = i + OFFSETS(d, 1);
        nj = j + OFFSETS(d, 2);

        % Skip out-of-bounds neighbours
        if ni < 1 || ni > nRows || nj < 1 || nj > nCols
            continue;
        end

        nNeighbours = nNeighbours + 1;

        if nanMask(ni, nj)
            % Unknown neighbour  →  off-diagonal coefficient  -1
            ptr = ptr + 1;
            rowIdx(ptr) = k;
            colIdx(ptr) = idxMap(ni, nj);
            vals(ptr)   = -1;
        else
            % Known neighbour  →  contributes to right-hand side
            b(k) = b(k) + Z(ni, nj);
        end
    end

    % Diagonal coefficient = number of in-bounds neighbours
    ptr = ptr + 1;
    rowIdx(ptr) = k;
    colIdx(ptr) = k;
    vals(ptr)   = nNeighbours;
end

% Trim unused pre-allocated space
rowIdx = rowIdx(1:ptr);
colIdx = colIdx(1:ptr);
vals   = vals(1:ptr);

% -------------------------------------------------------------------------
% 3.  Solve the system
% -------------------------------------------------------------------------
A = sparse(double(rowIdx), double(colIdx), vals, M, M);
x = A \ b;

% -------------------------------------------------------------------------
% 4.  Write the solution back into Z
% -------------------------------------------------------------------------
Z(nanIdx) = x;

end
