function [ start_location ] = synchronize( rx_bitstream )
%SYNCHRONIZE Performs initial acquisition of synchronization of receieved
%               data by calculation of the syndrome
%   INPUT arguments:        received bitstream
%
%   OUTPUT arguments:       location of start of synchronized bitstream

start_location = 1;
% find length of received stream
rx_stream_length = length(rx_bitstream);
offset = zeros(1, rx_stream_length-26);
% move bit by bit through the stream
for i=1:rx_stream_length-26
    % check the block (of 26 bits) starting from the current index i
    current_block = rx_bitstream(i:i+25);
    % generate offset index for the block (read syndrome.m for
    % correspondence between offset, offset index, and syndrome)
    [offset(i),~] = syndrome(current_block);
    
    % if the offset is valid
    if (offset(i)<10)
        % matrix to check if adjacent blocks are valid
        check_next = zeros(1,4);
        % check for validity of blocks nx26 bits apart, where n=1,2,3
        for n = 1:3
            % find the offset for the next block
            if (i+(n+1)*26-1 < length(rx_bitstream))
                [check_next(n),~] = syndrome(rx_bitstream(i+n*26:i+(n+1)*26-1));
                % find out if the offset is correct and in the valid order
                if (check_next(n) < 10 && check_next(n) == mod(offset(i)+n,4))
                    % if yes then keep the start location at the block whose
                    % expected offset is A
                    
                    % try to find the nearest start location of the group corresponding
                    % to the matched block
                    if (i - (offset(i)-1)*26 > 0)
                        start_location = i - (offset(i)-1)*26;
                        % if that is not possible keep it in the next group's
                        % expected starting location
                    else
                        start_location = i + (5-offset(i))*26;
                    end
                    return;
                end
            else
                start_location = 1;
                return;
            end
        end
    end
end