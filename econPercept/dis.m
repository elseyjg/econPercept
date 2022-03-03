function x = dis(va, mu, ul, ll, nvals)
n = makedist('Normal','mu', mu,'sigma',sqrt(va));
t = truncate(n,ll,ul);
x = floor(random(t,nvals,1) + 0.5);
end