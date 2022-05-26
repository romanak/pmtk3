%% 1d Gaussian MRF for inferring a function
% Based on p140 of "Introduction to Bayesian scientific computation"
% by Calvetti and Somersalo


function gmrf_1d()
   [obs, obsNdx, hidNdx] = make_data();
   demo(obs, obsNdx, hidNdx, sqrt(1/60));
   %demo(obs, obsNdx, hidNdx, 0.1)
   %demo(obs, obsNdx, hidNdx, 0.01)
end

function [obs, obsNdx, hidNdx] = make_data()
setSeed(0);
n = 100; %60;
Nobs = 6-2;
D = n+1; % numnber of variables
perm = randperm(D);
obsNdx = perm(1:Nobs);
obsNdx = sort([1, obsNdx, D]); % ensure boundaries are included
Nobs = length(obsNdx);
hidNdx = setdiff(1:D, obsNdx);
% Noisy observations of the x values at obsNdx
obsNoiseVar = 1;
obs = sqrt(obsNoiseVar)*randn(Nobs, 1);
end



function demo(obs, obsNdx, hidNdx, priorVar)
   D = length(obsNdx) + length(hidNdx);
   Nobs = length(obsNdx);
   n = D-1;
   
% Make a (n-1) * (n+1) tridiagonal matrix
L = 0.5*spdiags(ones(n-1,1) * [-1 2 -1], [0 1 2], n-1, n+1);

lambda = 1/priorVar; % precision
L = L*lambda;
L1 = L(:, hidNdx);
L2 = L(:, obsNdx);
B11 = L1'*L1;
B12 = L1'*L2;
B21 = B12';


%% Noise-free observations
% posterior on the Nhid hidden variables
postDist.mu = -inv(B11)*B12*obs;
postDist.Sigma = inv(B11);

% posterior on all D variables
mu = zeros(D,1);
mu(hidNdx) = -inv(B11)*B12*obs;
mu(obsNdx) = obs;
Sigma = 1e-5*eye(D,D);
Sigma(hidNdx, hidNdx) = inv(B11);
postDist.mu = mu;
postDist.Sigma = Sigma;

str = sprintf('obsVar=0, priorVar=%3.2f', priorVar);
makePlots(postDist, obs, obsNdx, hidNdx, str);
fname = sprintf('gmrf_1d_obsVar0_priorVar%s', ...
    int2str(round(100*priorVar)));
disp(fname)
printPmtkFigure(fname)

%% Noisy observations
obsNoiseVar = 0.2;
C = obsNoiseVar * eye(Nobs, Nobs);
GammaInv = [B11, B12;
        B21, B21 * inv(B11) * B12 + inv(C)];
Gamma = inv(GammaInv);  
Gamma = Gamma + 1e-5*eye(D,D);
postDist.Sigma = Gamma;
x  = [zeros(D-Nobs,1); obs];
postDist.mu = Gamma * x;

str = sprintf('obsVar=%2.1f, priorVar=%3.2f', obsNoiseVar, priorVar);
makePlots(postDist, obs,   obsNdx, hidNdx, str);
fname = sprintf('gmrf_1d_obsVar%s_priorVar%s', ...
    int2str(round(100*obsNoiseVar)), int2str(round(100*priorVar)));
disp(fname)
printPmtkFigure(fname)
end

function makePlots(postDist, y, obsNdx,  hidNdx, str)

D = length(hidNdx) + length(obsNdx);
xs = linspace(0, 1, D);
mu = postDist.mu;
S2 = diag(postDist.Sigma);

% plot marginal posterior sd as gray band
figure; hold on;

f = [mu+2*sqrt(S2); flipdim(mu-2*sqrt(S2),1)];
fill([xs'; flipdim(xs',1)], f, [7 7 7]/8, 'EdgeColor', [7 7 7]/8);

plot(xs(obsNdx), y, 'bx', 'markersize', 14, 'linewidth', 3);
plot(xs, mu, 'r-', 'linewidth', 2);


title(str)
set(gca, 'ylim',[-5 5]);

% plot samples from posterior predictive
for i=1:3
  fs = gaussSample(postDist, 1);
  plot(xs, fs, 'k-', 'linewidth', 1)
end

end


