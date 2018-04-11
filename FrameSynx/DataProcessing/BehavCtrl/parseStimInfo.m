function structs = parseStimInfo(stimInfo)

delimiter1 = '|';
delimiter2 = '=';
structs = {struct('Name',[])};
n = 1;

[tok,rest] = strtok(stimInfo,delimiter1);
[prop,val] = strtok(tok,delimiter2);
if ~isempty(val)
    return;
else
    structs{n}.Name = gstrtrim(prop);
end

while ~isempty(rest) % more tokens
    [tok,rest] = strtok(rest,delimiter1);
    [prop,val] = strtok(tok,delimiter2);
    if ~isempty(val)
        structs{n} = setfield(structs{n},gstrtrim(prop),gstrtrim(val(2:end)));
    else
        n = n+1;
        structs{n} = struct('Name',gstrtrim(prop));
    end
end