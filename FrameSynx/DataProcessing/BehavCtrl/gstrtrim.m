function out = strtrim(in)
pos1 = ~isspace(in);
out = in(pos1);