function y_filled = cubic_spline_fill(y)

x = transpose(1:length(y));

missing_x = find(isnan(y));

y_filled = y;

y_filled(isnan(y))=spline(x,y,missing_x);



