function words_info = add_diff(words_loc)
% Adds a third column to words_locs with the space between words.
% The last line has space of inf 

% For example: x1, y1, diff(x2,y1)
%              x2, y2, diff(x3,y2)
%              ...
%              xn, yn, inf

Diff = [];
for i=1:length(words_loc)-1
    diff_i = words_loc(i+1,1)-words_loc(i,2);
    Diff = [Diff,diff_i];
end
Diff = [Diff,inf];
words_info = [words_loc,Diff'];
end
