function [a, Sigma, B] = TME(x, f, L, Q, dt, order, simp)
% Giving the first two moments and covariance estimates from an SDE using
% the Taylor Moment Expansion (TME) method. Please see the references below
% for details.
%
% dx = f(x, t) dt + L(x, t) dB, 
%
% Notice that the code below is currently operated element-wisely for any 
% vector input, which is slow! It will be optimized later
%
% The inputs except `order` and `simp` must be symbolic
%
% Input:
%     x:      State vector (column)
%     f:      Drift function
%     L:      Dispersion function
%     Q:      Diffusion matrix
%     dt:     Time interval dt
%     order:  Order of expansion
%     simp:   Set "simplify" to output simplified results
% 
% Output:
%     a:      E[x(t+dt) | x(t)]
%     B:      E[x(t+dt)x^T(t+dt) | x(t)]
%     Sigma:  Cov[x(t+dt) | x(t)]  (By truncating B - aa^T)
%
% References:
%
%     [1] Zheng Z., Toni K., Roland H., and Simo S., Taylor Moment Expansion
%     for Continuous-discrete Filtering and Smoothing. 
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

dim_x = size(x, 1);

%% First moment
% See Definition III.1 of paper [1] for details
a = x;
phi = x;
for i = 1:order
    phi = z1(dim_x, x, phi, f, L, Q);
    a = a + (1/factorial(i)) * phi * dt^i;
end
fprintf('First moment gave. \n');

%% Second moment
% See Definition III.1 of paper [1] for details
B = x * x';
phi = x * x';
for i = 1:order
    phi = z2(dim_x, x, phi, f, L, Q);
    B = B + (1/factorial(i)) * phi * dt^i;
end
fprintf('Second moment gave. \n');

%% Covariance
% See Definition III.1 of paper [1] for details
% Truncate a * aT to keep degree of dt consistent
aaT = sym(zeros(dim_x, dim_x));
for u = 1:dim_x
    for v = 1:dim_x
        % Truncate each E[x_u] * E[x_v]
        aaT(u, v) = trunc(x(u), x(v), order, x, f, L, Q, dt);
    end
end
Sigma = B - aaT;
fprintf('Covariance gave. \n');

% Output simplified results?
if strcmpi(simp, 'simplify')
    a = simplify(a);
    B = simplify(B);
    Sigma = simplify(Sigma);
    fprintf('Simplified. \n');
end

function [out] = generator(x, phi, f, L, Q)
    % Infinitetestomial generator
    % x:    the state vector
    % phi:  scalar function
    % f:    The f
    % L, Q: The L, Q
    out = jacobian(phi, x) * f + 1/2 * trace(hessian(phi, x)' * (L*Q*L'));
end

function [out] = generator_kth(kth, x, phi, f, L, Q)
    % Infinitetestomial generator with k-th iteration
    % x:    the state vector
    % phi:  scalar function
    % f:    The f
    % L, Q: The L, Q
    out = phi;
    for iter = 1:kth
       out =  jacobian(out, x) * f + 1/2 * trace(hessian(out, x)' * (L*Q*L'));
    end
end

function [out] = z1(dim, x, phi, f, L, Q)
    % An operator R^D -> R^D applying generator element-wisely
    % phi: R^D vector
    % x:   state vector
    out = sym(zeros(dim, 1));
    for k = 1:dim
        out(k) = generator(x, phi(k), f, L, Q);
    end
end

function [out] = z2(dim, x, phi, f, L, Q)
    % An operator R^D*D -> R^D*D applying generator element-wisely
    % phi: R^D*D matrix
    % x:   state vector
    out = sym(zeros(dim, dim));
    for j = 1:dim
        for k = 1:dim
            out(j, k) = generator(x, phi(j, k), f, L, Q);
        end
    end
end

function [out] = trunc(xu, xv, order, x, f, L, Q, dt)
    % Give the truncated E[x_u]*E[x_v] up to the given order
    % See Remark III.1 of paper [1] for details
    out = 0;
    for ii = 0:order
        cauc = 0;
        for jj = 0:ii
            cauc = cauc + 1 / (factorial(jj) * factorial(ii-jj)) * ...
                generator_kth(jj, x, xu, f, L, Q) * ...
                generator_kth(ii-jj, x, xv, f, L, Q);
        end
        out = out + cauc * dt^ii;
    end
end

end