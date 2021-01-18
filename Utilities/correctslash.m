function path = correctslash(path)

if ispc
    path = strrep(path,'/','\');
else
    path = strrep(path,'\','/');
end