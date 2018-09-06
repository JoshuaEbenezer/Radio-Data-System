function [  ] = message_display( rx_information )
%MESSAGE_EXTRACTION Function takes in the received information and displays
%                   the message in a readable format 
%   INPUT arguments:        received RDS information
%
%   OUTPUT arguments:       -
%
%   Author:                 Joshua Peter Ebenezer
%   Date of creation:       December 12, 2017

% number of messages
no_msgs = floor(length(rx_information)/64);

for i=1:no_msgs
    % taking out one group at a time
    group = rx_information((i-1)*64+1:i*64);
    
    % splitting up the blocks' information
    info1 = group(1:16);
    info2 = group(17:32);
    info3 = group(33:48);
    info4 = group(49:64);
    
    % PI code
    pi_hex = dec2hex(bin2dec(int2str(info1)));
    fprintf('\nPI code is given by %s', pi_hex);
    
    
    
    % group type
    group_type = bin2dec(int2str(info2(1:4)));
    fprintf('\nGroup type is %d',group_type);
    
    % version (0-A 1-B)
    if (info2(5)==0)
        version = 'A';  % PI code is only inserted in block 1
    else
        version ='B';   % PI code is inserted in blocks 1 and 3
    end
    fprintf('\nVersion is %s',version);
    
    % traffic programme code
    traffic_code = info2(6);
    if (traffic_code == 0)
        fprintf('\nTraffic programme information is not present');
    else
        fprintf('\nTraffic programme information is present');
    end
    
    % programme type code
    pty = info2(7:11);
    fprintf('\nProgramme type code is');
    disp(pty);
    
    % traffic announcement
    ta = info2(12);
    if (ta == 0)
        traff = 'OFF';
    else
        traff = 'ON';
    end
    fprintf('\nTraffic announcements are %s', traff);
    
    % music or speech
    ms = info2(13);
     if (ms == 0)
        mors = 'Speech';
    else
        mors = 'Music';
    end
    fprintf('\nMusic/Speech: %s\n', mors);
    
end
end

