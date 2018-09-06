function [ rds ] = pulse_shape( biphase,L,Fs )
%PULSE_SHAPE Applies pulse shaping to biphase symbols (impulse pairs)
%   INPUT arguments:        biphase impulse pairs, frequency of sampling
%
%   OUTPUT arguments:       rds (shaped)
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 6th, 2017
%  

% time step
Ts = 1/Fs;
% sampling time array
t = (-L/2:L/2)*Ts;


% frequency
f = Fs*(0:(L/2))/L;

% option 1 - hardcoding the filter by deriving the impulse response
% filter = 1/(2*pi) * (sin(4750*pi*(t+td/8))./(t+td/8) + sin(4750*pi*(t-td/8))./(t-td/8)) ;

% option 2 - designing the puslse shaping filter
% The rolloff is 100% (pure cosine)
rolloff = 1;

% Here each bit is represented by an impulse pair. Hence number of symbols
% must be twice the number of bits
no_of_symbols = 4*max(t)*19000*3/48;

% sps must be 100 because each bit has 200 samples and hence each symbol
% will have half of that
samples_per_symbol = 100;
 
filter = rcosdesign(rolloff,no_of_symbols,samples_per_symbol);

% impulse response of pulse shaping filter
figure;
zero_ind = find(t==0);
plot(t(zero_ind-1e3:zero_ind+1e3),filter(zero_ind-1e3:zero_ind+1e3));
title('Impulse response of pulse shaping filter (truncated time interval)');
xlabel('Time(in seconds)');
ylabel('Amplitude');
% plot frequency response
[H,f1] = freqz(filter,1,2048,Fs);

figure;
subplot(2,1,1);
plot(f1,abs(H));
title('Frequency response of pulse shaping filter');
xlabel('Frequency(in Hz)');
ylabel('Amplitude');
subplot(2,1,2);
plot(f1,unwrap(angle(H)));
title('Phase response of pulse shaping filter');
xlabel('Frequency(in Hz)');
ylabel('Phase');

% perform convolution
rds = conv(biphase,filter,'same');

% amplify the signal
loss = max(rds)/max(biphase);
rds = 10*rds/loss;

figure;
subplot(2,1,1);
plot(biphase(1:2000));
title('Biphase');

subplot(2,1,2);
plot(rds(1:2000));
title('RDS');
%% --------------------- Find and display fft of RDS ------------- %%
fm_rds_Y = fft(rds);
% double sided spectrum
P2 = abs(fm_rds_Y/L);
% single sided spectrum
FM_RDS_FT = P2(1:L/2+1);

% recover exact amplitudes
FM_RDS_FT(2:end-1) = 2*FM_RDS_FT(2:end-1);

figure;
plot(f,FM_RDS_FT) 
title('Single-Sided Amplitude Spectrum of RDS at baseband');
xlabel('f (Hz)');
ylabel('|FT(f)|');
end