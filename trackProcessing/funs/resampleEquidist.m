function re = resampleEquidist(inDat, s, M, type)
% https://stackoverflow.com/questions/19117660/how-to-generate-equispaced-interpolating-values
% Find lots of points on the piecewise linear curve defined by x and y
% Inputs: inDat: table of tracks
%         s: Resample step length [px] (should be ~median or mode step length)
%         M: #of interpolated points between each input point
%         type: "disp"; % "trav" for distance travelled, "disp" for net displacement

x1 = inDat.x(1:end-1);
x2 = inDat.x(2:end);
y1 = inDat.y(1:end-1);
y2 = inDat.y(2:end);
t1 = inDat.t(1:end-1);
t2 = inDat.t(2:end);
x = bsxfun(@plus,((x2(:)-x1(:))./(M-1))*(0:M-1),x1(:))';
y = bsxfun(@plus,((y2(:)-y1(:))./(M-1))*(0:M-1),y1(:))';
t = bsxfun(@plus,((t2(:)-t1(:))./(M-1))*(0:M-1),t1(:))';
x = x(:);
y = y(:);
t = t(:);

% Find first interpolated point @ which inDat has travelled >thresh distance
i = 1;
idx = 1;
while i < height(x)
    disp = 0;
    for j = i+1:height(x)-1
        if type == "trav"
            disp = disp + sqrt((x(j)-x(j-1))^2 + (y(j)-y(j-1))^2);
        elseif type == "disp"
            disp = sqrt((       x(j)-x(i  ))^2 + (y(j)-y(i  ))^2);
        end
        if disp >= s
            idx(end+1) = j;
            break
        end
    end
    i = j+1;
end

xn = x(idx);
yn = y(idx);
tn = t(idx);
idn = repmat(inDat.id(1),length(xn),1);
re = array2table([xn yn tn idn],'variablenames',{'x' 'y' 't' 'id'});
