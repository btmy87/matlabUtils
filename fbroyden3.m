function [x, y, exitflag, output, J] = fbroyden3(fun, x0, opts)
% fbroyden find zero of a multivariate function using Broyden's method

% validate inputs
arguments
    fun (1, 1) function_handle
    x0 (:, 1) double {mustBeFinite}
    opts.TolX (:, 1) = 1.0e-6 + 1.0e-6.*abs(x0);
    opts.FunValCheck (1, 1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off;
    opts.MaxIter (1, 1) {mustBeFinite} = 100;
    opts.MaxFunEvals(1, 1) {mustBeFinite} = 100;
    opts.Display (1, 1) string {mustBeMember(opts.Display, ["notify", "final", "off", "none", "iter"])} = "off";
    opts.J0 (:, :) double {mustBeFinite} = [];
    opts.LineSearchMultiplier (1, 1) double {mustBePositive} = 0.5;
    opts.DeltaX (:, 1) double = 1.0e-5 + 1.0e-5.*abs(x0);
    opts.DeltaXMax (:, 1) double {mustBePositive} = 0.1 + 0.1.*abs(x0);
    opts.Sparse (1, 1) {mustBeNumericOrLogical} = false;
end

if isscalar(opts.TolX)
    opts.TolX = opts.TolX.*ones(size(x0));
end
n = length(x0);
assert(n == length(opts.TolX));

if opts.Display == "none"
    opts.Display = "off";
end

% make output structure
output = struct();
output.intervaliterations = nan;
output.iterations = 0;
output.funcCount = 0;
output.algorithm = "broyden";
output.message = "";
output.xSteps = zeros(opts.MaxFunEvals, n);
output.ySteps = zeros(opts.MaxFunEvals, n);
output.procedure = strings(opts.MaxFunEvals, 1);
exitflag = 0;

% initialize
i = 1;
x = x0;
y = fun(x);
J = opts.J0;
if isempty(J)
    J = estimate_jacobian(fun, x, opts.DeltaX);
end
output.xSteps(1, :) = x;
output.ySteps(1, :) = y;
output.procedure(1) = "initial";
if opts.Display == "iter"
    print_step(output, 1);
end

% save jacobian sparsity pattern
Js = ones(n);
Js(J == 0.0) = 0.0;

% main iteration loop
for i1 = 2:opts.MaxIter
    % calculate nominal step in jacobian direction
    dxnom = J\(-y);
    sind = abs(opts.DeltaXMax)./abs(dxnom); % individual scale factors
    s = min(min(sind), 1.0); % starting scale factor
    dx = s.*dxnom;

    % check for convergence
    if all(abs(dxnom) < opts.TolX)
        exitflag = 1;
        break;
    end
    s = 1.0; % step size multiplier
    while i < opts.MaxFunEvals
        % try the step
        i = i + 1;
        xnew = x + s.*dx;
        ynew = fun(xnew);
        output.xSteps(i, :) = xnew;
        output.ySteps(i, :) = ynew;
        if s == 1.0
            output.procedure(i, :) = "Broyden";
        else
            output.procedure(i, :) = "LineSearch";
        end

         %check for progress
         if norm(ynew) < norm(y)
             break; % :)
         end

         % try a smaller step
         s = s.*opts.LineSearchMultiplier;
    end
    
    % check for max func evals
    if i >= opts.MaxFunEvals
        output.message = "Did not converge.  Reached maximum number of function evaluations.";
        break; % :(
    end

    % update jacobian
    dy = ynew-y;
    if opts.Sparse
        dJ = zeros(n);
        for j = 1:n
            dxs = dx.*Js(j, :)'; % sparse dx
            if any(dxs~=0)
                dJ(j, :) = (ynew(j)-(1.0-s)*y(j))*dxs'./s./(dxs'*dxs);
            end
        end
    else
        % normal dense Broyden update
        dJ = (dy - s*J*dx)*dx'/(s*(dx'*dx));
    end
    J = J + dJ;

    % accept step
    x = xnew;
    y = ynew;

end

output.iterations = i1;
output.funcCount = i;

end

function J = estimate_jacobian(fun, x, dx)
% estimate_jacobian estimate value of jacobian at location x using step
% size dx

% initialize
n = length(x);
J = zeros(n, n);

% save base values
y0 = fun(x);

% perturb inputs and build jacobians
for i = 1:n
    x1 = x;
    x1(i) = x1(i) + dx(i);
    y1 = fun(x1);
    J(:, i) = (y1-y0)./dx(i); 

end

end

function print_step(output, i)
    fprintf("Iter %5d, %s, x = [%s], y = [%s]\n", i, ...
        output.procedure(i), ...
        formattedDisplayText(output.xSteps(i, :)), ...
        formattedDisplayText(output.ySteps(i, :)));
end