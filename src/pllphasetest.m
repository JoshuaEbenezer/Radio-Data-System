clc;
close all;
clear;

%% -- For phase deviation--%
% number of sampling instances 
L = 1e6;
% frequency of sampling 
Fs = 150e3;
% time step
Ts = 1/Fs;
% last sampling instance
tmax = (L/2)*Ts;
% sampling time array
t = (0:L-1)*Ts;
% frequency
f = Fs*(0:(L/2))/L;

pilot = awgn(cos(2*pi*19e3*t+pi/20),20);

carr1 = pll(pilot,3);
carr2 = 4*pilot.^3-3*pilot;
reference = cos(2*pi*57e3*t+3*pi/20);

xref = hilbert(cos(2*pi*57e3*t*Ts+3*pi/20));
xc1 = hilbert(carr1);
P1 = (angle(xc1.*conj(xref)));

xc2 = hilbert(carr2);
P2 = (angle(xc2.*conj(xref)));
% figure;
% % plot(t(5000:5100),carr1(5000:5100),'b');
% plot(t(4500:5100),carr2(4500:5100),'k','LineWidth',2);
% hold on;
% plot(t(4500:5100),reference(4500:5100),'--or');

% 
% refbad = cos(2*pi*57e3*t);
% hold on;
% plot(t(5000:5100),refbad(5000:5100),'--vg');
% 
