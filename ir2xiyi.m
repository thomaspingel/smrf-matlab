function [xi yi] = ir2xiyi(I,R)
    r = size(I,1);
    c = size(I,2);
    [xb yb] = pix2map(R,[1 r],[1 c]);
    xi = xb(1):R(2):xb(2);
    yi = yb(1):R(4):yb(2);
end
