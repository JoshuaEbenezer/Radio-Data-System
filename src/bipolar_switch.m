function [ bipolar ] = bipolar_switch( signal, sps )
%BIPOLAR_SWITCH 
%   samples signal for half a time period and it's inverted version for the
%   next half a time period
%   INPUT arguments:            Signal to be sampled, samples per
%                               symbol(must be even)
%
%   OUTPUT arguments:           Bipolar switching's sampled output
%
%   Author:                     Joshua Peter Ebenezer
%   Date of creation:           7th December, 2017

% initialize the output
bipolar = signal;

% number of symbols
symb_count = length(signal)/sps;

% to ensure that sps is an integer multiple of 4 (if clock freq is not
% matched perfectly)
sps_int = round(sps);
sps_gap = round(sps/4);

% flip sample whenever half the time period has elapsed
for i=1:symb_count
    bipolar((i-1)*sps_int+sps_gap:(i-1)*sps_int+3*sps_gap) = -signal((i-1)*sps_int+sps_gap:(i-1)*sps_int+3*sps_gap);
end

%% plot the signal and the bipolar sampled signal

% number of sampling instances 
L = 9.5e5;

% frequency of sampling 
Fs = 2.375e5;
% time step
Ts = 1/Fs;
% sampling time array
t = (-L/2:L/2-1)*Ts;

zero_ind = find(t==0);

figure;
subplot(2,1,1);
plot(t(zero_ind-1e3:zero_ind+1e3),signal(zero_ind-1e3:zero_ind+1e3));
plot(t(1:2000),signal(1:2000));
title('Biphase encoded signal before bipolar sampling');

subplot(2,1,2);
plot(t(zero_ind-1e3:zero_ind+1e3),bipolar(zero_ind-1e3:zero_ind+1e3));
plot(t(1:2000),bipolar(1:2000));
title('Bipolar sampled signal');

end

