clc;
close all;
clear;
%% -- For frequency deviation--%
% number of sampling instances 
L = 1e6;
% frequency of sampling 
Fs = 150e3;
% time step
Ts = 1/Fs;
% last sampling instance
tmax = (L)*Ts;
% sampling time array
t = (0:L-1)*Ts;
% frequency
f = Fs*(0:(L/2))/L;

pilot = cos(2*pi*19.002e3*t);
pilot_gauss = awgn(pilot,20);
% pilot = cos(2*pi*19.002e3*t);
carr_trig = 4*pilot_gauss.^3-3*pilot_gauss;
carr_pll = pll(pilot_gauss,3);
reference = cos(2*pi*3*19.002e3*t);
% 
% carr_trig_fft = fft(carr_trig);
% % double sided spectrum
% P2 = abs(carr_trig_fft/L);
% % single sided spectrum
% carr_trigFT = P2(1:L/2+1);
% % recover exact amplitudes
% carr_trigFT(2:end-1) = 2*carr_trigFT(2:end-1);
% figure;
% plot(f/1000,carr_trigFT);
% xlabel('f (kHz)');
% ylabel('|FT(f)|');
% 
% carr_pll_fft = fft(carr_pll);
% % double sided spectrum
% P2 = abs(carr_pll_fft/L);
% % single sided spectrum
% carr_pllFT = P2(1:L/2+1);
% % recover exact amplitudes
% carr_pllFT(2:end-1) = 2*carr_pllFT(2:end-1);
% figure;
% plot(f/1000,carr_pllFT);
% xlabel('f (kHz)');
% ylabel('|FT(f)|');