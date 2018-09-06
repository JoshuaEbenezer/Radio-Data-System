function [ carrier ] = pll( pilot, harmonic )
%PLL Takes pilot tone (19 kHz) and harmonic of carrier and returns phase-locked
%carrier
%   INPUT arguments:    Pilot signal and harmonic (1st,2nd,3rd..)
%   
%   OUTPUT arguments:   Carrier signal (phase locked to harmonic of pilot)
%   
%   Author:             Joshua Peter Ebenezer
%   Date:               December 26th, 2017


% % number of sampling instances
% L = 9.5e5;
% % frequency of sampling
% Fs = 2.375e5;
% % time step
% Ts = 1/Fs;

%% UNCOMMENT FOR FREQUENCY DEVIATION
% number of sampling instances 
L = 1e6;
% frequency of sampling 
Fs = 150e3;
% time step
Ts = 1/Fs;
%% UNCOMMENT FOR PHASE DEVIATION
% % number of sampling instances 
% L = 1e6;
% % frequency of sampling 
% Fs = 1e7;
% % time step
% Ts = 1/Fs;

% Ideal carrier frequency
fVCO = harmonic * 19000; %free running oscillating freq of VCO
KVCO = fVCO*0.1;    % gain of VCO (voltage to freq transfer coeff.) [Hz/V]
G1 = 0.08;        % Prop gain term of PI controller
G2 = 0.02;      % integral gain term of PI controller

% PLL LPF (for integration of error, removal of noise from error)
fc = 1e3;  % frequency of LPF 
fil_coeff_num = 500; %number of filter coeffs of LPF

% BPF after squaring or cubing pilot signal
harm_fil_order = 600;    %order of filter
harm_fil_freq_range = [fVCO-10,fVCO+10]; %pass band
% bpf initialization
bpf = fir1(harm_fil_order,harm_fil_freq_range/(Fs/2));
%FIR filter coefficients
harm_fil_buffer = zeros(1,harm_fil_order+1);
harmonic_input_filtered = zeros(1,L);

% PLL initialization
pll_fil = fir1(fil_coeff_num,fc/(Fs/2)); % design FIR filter coeff
VCO = zeros(1,L); % VCO signal array
phi = zeros(1,L); % VCO angle array
error = zeros(1,L); % error array
int_error = zeros(1,L); % error array
filter_buffer = zeros(1,fil_coeff_num+1); % initialize PLL LPF buffer
error_mult = zeros(1,L); % initialize error signal
reference = zeros(1,L);
PI_error = zeros(1,L);
carrier = zeros(1,L);
input_harmonic = zeros(1,L);

%% Begin sampled time simulation %%
for n=1:L
    tn = (-L/2 + (n-1))*Ts;
    
    % Find harmonic of received signal
    input_harmonic(n) = pilot(n)^harmonic;
    
    % send through BPF to extract harmonic term alone
    harm_fil_buffer = [harm_fil_buffer(2:harm_fil_order+1),input_harmonic(n)];
    harmonic_input_filtered(n+1) = fliplr(bpf)*harm_fil_buffer.'; %BPF operation
    reference(n) = harmonic_input_filtered(n); % signal that goes to PLL
        
    % PLL calculations
    error_mult(n) = harmonic_input_filtered(n)*VCO(n); % multiply VCO x signal input to get raw error signal
    
    % LPF raw error signal
    filter_buffer = [filter_buffer(2:fil_coeff_num+1),error_mult(n)]; % update PLL LPF buffer
    error(n+1) = 2*fliplr(pll_fil)*filter_buffer.';       
    
    % process filtered error signal through PI controller
    int_error(n+1) = int_error(n)+G2*error(n)*Ts;
    PI_error(n+1) = G1*error(n+1)+int_error(n+1);
    
    % update VCO
    phi(n+1) = phi(n)+2*pi*PI_error(n+1)*KVCO*Ts; % update phase of VCO
    VCO(n+1) = -sin(2*pi*fVCO*tn+phi(n+1));   % compute VCO signal

    % VCO_shifted(n+1) = sin(2*pi*fVCO*t+phi(n+1)-pi/2); % shift output of PLL by 90 degrees
    carrier(n) = cos(2*pi*fVCO*tn+phi(n));

end
end
