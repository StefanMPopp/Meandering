function tr = trackLastDigitFun(tr,varargin)
% Input: Track, if array: ID must be column 4.
%        Level: only last digit, 2 = last two digits
% Output: last digit of ID in last column
if istable(tr)
    lastDigit = num2str(tr.id,'%02.f');
    tr.color = str2num(lastDigit(:,end)); % color by ID
    if size(varargin,1) > 0
        tr.color2 = str2num(lastDigit(:,end-1));
    end
else
    lastDigit = num2str(tr(:,4),'%02.f');
    tr(:,end+1) = str2num(lastDigit(:,end)); % color by ID
    if size(varargin,1) > 0
        tr(:,end+1) = str2num(lastDigit(:,end-1));
    end
end