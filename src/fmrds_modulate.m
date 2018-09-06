function [ fm_rds_signal ] = fmrds_modulate( left, right, rds, pilot_freq,L,Fs)
%% TRANSMIT Function to modulate FM RDS broadcast (before FM stage)
%   INPUT arguments:        Left and right stereo audio, RDS bitstream,
%                           carrier frequency, length of time base, sampling frequency 
%   OUTPUT arguments:       Frequency modulated broadcast 
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 4th, 2017
 
% sum of left and right signals (main channel baseband)
stereo_sum = left+right;

% difference of left and right signals (centred at twice the carrier
% frequency)
stereo_diff = left-right;
% time step
Ts =1/Fs;
% sampling time array
t = (-L/2:L/2-1)*Ts;

figure;
subplot(2,1,1);
plot(t(1:5000),stereo_diff(1:5000))
title('Stereo diff');
xlabel('t (secs)');
ylabel('L-R(t)');

subplot(2,1,2);
plot(t(1:5000),stereo_sum(1:5000))
title('Stereo sum');
xlabel('t (secs)');
ylabel('L+R(t)')

% pilot frequency in radians (19kHz in radians)
carrier_omega = pilot_freq*2*pi;

% multiply the rds signal with the 57kHz carrier
rds_band = 2*rds.*cos(3*carrier_omega*t);

figure;
zero_ind = find(t==0);
plot(t(zero_ind-3e2:zero_ind+2e2),rds_band(zero_ind-3e2:zero_ind+2e2));
title('RDS on 57 kHz carrier (time domain)');
xlabel('Time(s)');
ylabel('RDS signal amplitude');

% sub channel difference signal centred at 38kHz
sub_channel = 2*stereo_diff.*cos(2*carrier_omega*t);

% rds_band = awgn(rds_band,snr,'measured');
% pilot tone for synchronous detection
pilot_tone = cos(carrier_omega*t);
% sum the signals to get the broadcast
fm_rds_signal = stereo_sum + sub_channel + pilot_tone + rds_band;
end


