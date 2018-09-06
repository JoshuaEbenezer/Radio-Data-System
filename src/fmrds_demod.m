function [left_rec, right_rec, pilot, rds] = fmrds_demod(fm_rds_signal,Fs,L)
% RECEIVE receive and demodulate fm rds broadcast
%   INPUT arguments:        FM RDS broadcast, sampling frequency, length of
%                           time base
%   OUTPUT arguments:       left stereo signal, right stereo signal, pilot
%                           tone, differential encoded RDS data
%   Functions called:       bipolar_switch
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 4th, 2017

% time base
t = (-L/2:L/2-1)/Fs;

% frequency
f = Fs*(0:(L/2))/L;

%% Extract pilot tone
% designing elliptical bandpass filter
filter_order = 2;
passband_ripple = 0.1;
stopband_atten = 80;

pilot_passband = [18e3 20e3]/(Fs/2);

ftype = 'bandpass';

% Zero-Pole-Gain design to avoid numerical instabilities
[zpilot,ppilot,kpilot] = ellip(filter_order,passband_ripple,stopband_atten,pilot_passband,ftype);
% convert to second order sections for implementation
sos = zp2sos(zpilot,ppilot,kpilot);

pilot = sosfilt(sos, fm_rds_signal);

pilot_fft = fft(pilot);
% double sided spectrum
P2 = abs(pilot_fft/L);
% single sided spectrum
PILOT_FT = P2(1:L/2+1);

% recover exact amplitudes
PILOT_FT(2:end-1) = 2*PILOT_FT(2:end-1);

figure;
plot(f,PILOT_FT) 
title('Single-Sided Amplitude Spectrum Pilot tone');
xlabel('f (Hz)');
ylabel('|FT(f)|');

% normalize tone
% pilot = pilot;

% generate carrier for 38 kHz stereo difference signal using trig identity
diff_carrier = 2*pilot.^2-1;

% generate carrier for 57 kHz RDS signal using trig identity
rds_carrier = 4*pilot.^3 - 3*pilot;


[~,pilot_ind] = max(PILOT_FT(:));
pilot_freq = max(f(pilot_ind));
% extract clock frequency for RDS from pilot tone
clk_freq = pilot_freq/16;

%% Low pass filtering to retrieve the stereo sum signal (L+R) (within 15kHz)
% Design low pass filter
% cutoff frequency normalized wrt Nyquist frequency
cutoff = 10e3/(Fs/2);

% order of filter
order = 64;

% impulse response of filter
lowpassh = fir1(order, cutoff);

figure;
% magnitude and phase response of the filter
freqz(lowpassh);
title('Frequency response of low pass filter');

% extract stereo sum signal
stereo_sum = conv(fm_rds_signal,lowpassh,'same');

%% Find and display FFT of the stereo sum signal
% fft of signal
stereo_sum_fft = fft(stereo_sum);
% double sided spectrum
P2 = abs(stereo_sum_fft/L);
% single sided spectrum
stereo_sum_FT = P2(1:L/2+1);
% recover exact amplitudes
stereo_sum_FT(2:end-1) = 2*stereo_sum_FT(2:end-1);

figure;
subplot(2,1,1);
plot(f,stereo_sum_FT)
title('Single-sided amplitude spectrum of (L+R) signal at receiver end');
xlabel('f (Hz)');
ylabel('|(L+R)FT(f)|');
%% Bandpass filtering to retrieve the stereo difference (L-R) signal centred at 38kHz
% 
% designing elliptical bandpass filter
% filter order
filter_order = 4;
passband = [23e3 53e3]/(Fs/2);
ftype = 'bandpass';

% Zero-Pole-Gain design  
[z,p,k] = butter(filter_order,passband,ftype);
sosdiff = zp2sos(z,p,k);

stereo_diff_band = sosfilt(sosdiff, fm_rds_signal);

% multiply signal with tonal to shift the stereo difference to baseband
base_stereo_diff = stereo_diff_band.*diff_carrier;

% Use the previous low pass filter
% extract stereo difference signal
stereo_diff = conv(base_stereo_diff,lowpassh,'same');

%% Find and display FFT of the stereo difference (L-R) signal
% fft of signal
stereo_diff_fft = fft(stereo_diff);
% double sided spectrum
P2 = abs(stereo_diff_fft/L);
% single sided spectrum
stereo_diff_FT = P2(1:L/2+1);
% recover exact amplitudes
stereo_diff_FT(2:end-1) = 2*stereo_diff_FT(2:end-1);

subplot(2,1,2);
plot(f,stereo_diff_FT)
title('Single-sided amplitude spectrum of (L-R) signal at receiver end');
xlabel('f (Hz)');
ylabel('|(L-R)FT(f)|');

%% Compute the left stereo signal and the right stereo signal

left_rec = (stereo_sum + stereo_diff)/2;
right_rec = (stereo_sum - stereo_diff)/2;

%% Find and display FFT of the LEFT signal
% fft of signal
left_fft = fft(left_rec);
% double sided spectrum
P2 = abs(left_fft/L);
% single sided spectrum
left_FT = P2(1:L/2+1);
% recover exact amplitudes
left_FT(2:end-1) = 2*left_FT(2:end-1);

figure;
subplot(2,1,1);
plot(f,left_FT)
title('Single-sided amplitude spectrum of left signal at receiver end');
xlabel('f (Hz)');
ylabel('|LEFT FT(f)|');

%% Find and display FFT of the RIGHT signal
% fft of signal
right_fft = fft(right_rec);
% double sided spectrum
P2 = abs(right_fft/L);
% single sided spectrum
right_FT = P2(1:L/2+1);
% recover exact amplitudes
right_FT(2:end-1) = 2*right_FT(2:end-1);

subplot(2,1,2);
plot(f,right_FT)
title('Single-sided amplitude spectrum of right signal at receiver end');
xlabel('f (Hz)');
ylabel('|RIGHT FT(f)|');

%% Display the time-domain received signals (both left and right)
zero_ind = find(t==0);

figure;
subplot(2,1,1);
plot(t(zero_ind-1e3:zero_ind+1e3),left_rec(zero_ind-1e3:zero_ind+1e3))
title('Left signal (time domain) at receiver end');
xlabel('t (secs)');
ylabel('left(t)');

subplot(2,1,2);
plot(t(zero_ind-1e3:zero_ind+1e3),right_rec(zero_ind-1e3:zero_ind+1e3))
title('Right signal (time domain) at receiver end');
xlabel('t (secs)');
ylabel('right(t)');

%% Extract RDS encoded bit-stream

% designing elliptical bandpass filter
filter_order = 2;
rds_passband = [54.6e3 59.4e3]/(Fs/2);
ftype = 'bandpass';
passband_ripple = 0.01;
stopband_atten = 100;

% Zero-Pole-Gain design 
[z,p,k] = ellip(filter_order,passband_ripple,stopband_atten, rds_passband,ftype);
sos = zp2sos(z,p,k);

rds_band = sosfilt(sos, fm_rds_signal);

% multiply signal with tonal to shift the rds signal to baseband
base_rds = rds_band.*rds_carrier;

% Use a low pass filter
% Design low pass filter
% cutoff frequency normalized wrt Nyquist frequency
cutoff = 2.375e3/(Fs/2);

% order of filter
order = 64;

% impulse response of filter
lowpass_rds = fir1(order, cutoff);

% extract biphase encoded rds signal
biphase_code_rds = conv(base_rds,lowpass_rds,'same');

samples_per_symbol = Fs/clk_freq;

% sample the signal and it's inverted version with a bipolar switch
uni_rds = bipolar_switch(biphase_code_rds,samples_per_symbol);

% integrate and dump
rds_analog = intdump(uni_rds,samples_per_symbol);


figure;
stairs(rds_analog(end/2-4:end/2+5));
title('Output of integration and dumping');
xlabel('Bit index');

% slicer
rds = rds_analog>0;

%% Find and display FFT of the RDS baseband biphase encoded signal (o/p of filter)
% fft of signal
rds_fft = fft(biphase_code_rds);
% double sided spectrum
P2 = abs(rds_fft/L);
% single sided spectrum
rds_FT = P2(1:L/2+1);
% recover exact amplitudes
rds_FT(2:end-1) = 2*rds_FT(2:end-1);

figure;
plot(f,rds_FT)
title('Single-sided amplitude spectrum of RDS signal at receiver end');
xlabel('f (Hz)');
ylabel('|RDS FT(f)|');
end