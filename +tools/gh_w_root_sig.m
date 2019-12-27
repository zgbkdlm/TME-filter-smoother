function [weights, groot, sigp] = gh_w_root_sig(n, p, type, varargin)
% Generate weights, roots and sigma points for Gauss-Hermite 
%   The weight and root are determined by state dimension and order
% Input:
%     n:    dimension of state
%     p:    polynomial order
%     type: Physician (default) or statistician type of Hermite
%     'static': (optional) will create static .mat to store the weights and roots
%
% Output:
%     weights: Sigma point weights
%     groot:   I'm Groot!
%     sigp:    Sigma point
%
% Zheng Zhao @ 2019 Aalto University
% zz@zabemon.com 
%
% Copyright (c) 2018 Zheng Zhao
% 
% Verson 0.1, Dec 2018

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or 
% any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%

% Number of sigma points is n^p
weights = zeros(1, p^n);

%% Roots
if ~strcmpi(type, 'stat')
    % Generate Hermite Polynomial (Physician Hermite) Default
    % H0 = 1
    % H1 = 2x
    % H2 = 4*x^2 - 2
    % ...
    % H(p+1) = 2*x*H(p) - 2*p*H(p-1)
    x = sym('x', [1 1]);
    H0 = 1;
    H1 = 2 * x;
    H = [H0; H1];
    for i = 2:p
        H = [H; 2*x*H(i)-2*(i-1)*H(i-1)];
    end
else
    % Statistician Hermite
    % H0 = 1
    % H1 = x
    % H2 = x^2 - 1
    % ...
    % H(p+1) = x*H(p) - p*H(p-1)
    x = sym('x', [1 1]);
    H0 = 1;
    H1 = x;
    H = [H0; H1];
    for i = 2:p
        H = [H; x*H(i)-(i-1)*H(i-1)];
    end
end

poly_coeff = double(coeffs(H(end), x, 'All'));
groot = roots(poly_coeff)';   % Confliction of using key arg 'roots' and 'root', use groot instead. 

%% Generate weights and sigma points
% Weights should have n^p elements, with each looks like: w1w1w1w1 w1w1w1w2
% w1w1w1w3 ... w1w1w1wp. ....
% similar to the sigma points x1x1x1x1 x1x1x1x2 ......
% we will form a table like:
% 1 1 1 1 1 1 1 1 1 1 1 1
% 1 1 1 1 1 1 1 1 1 2 2 2
% 1 1 1 2 2 2 3 3 3 1 1 1
% 1 2 3 1 2 3 1 2 3 1 2 3
table = zeros(n, p^n);

% Get all w1, w2, ... wp
w_1d = zeros(1, p);
for i = 1:p
    w_1d(i) = 2^(p-1) * factorial(p) * sqrt(pi) / (p^2 * (subs(H(p), groot(i)))^2);
end

% Don't ask how I derived this, I just know.
for i = 1:n
    base = repmat([1], [1, p^(n-i)]);
    for j = 2:p
        base = [base repmat([j], [1, p^(n-i)])];
    end
    table(n-i+1, :) = repmat(base, [1, p^n / (p^(n-i+1))]);
end

weights = prod(w_1d(table), 1);
sigp = groot(table);

end

