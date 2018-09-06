function [ slip ] = bitslip( block, pi_code )
%BITSLIP Alerts program to slip in clocking of data. Returns slip to be
%        compensated
%   INPUT arguments:        block (of data), pi_code
%   
%   OUTPUT arguments:       slip
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 12th, 2017


[cross_correlation,lags] = xcorr(block,pi_code);

[~, lag_index] = max(abs(cross_correlation));

slip = lags(lag_index);
end

