function out = select_output(iout, f, varargin)
% select_output returns output number iout from function f
%
% INPUTS:
%  - iout: index of output to return
%  - f: function handle to evaluate
%  - varargin: inputs to function
%
% NOTES:
%  - useful when trying to pass function handles to other functions, like
%  fzero, that need a scalar valued function handle.
%
% EXAMPLE:
% >> select_output(2, @min, [1,2,3,4,0,6])
% ans = 
%        5

[y{1:iout}] = f(varargin{:});
out = y{iout};
