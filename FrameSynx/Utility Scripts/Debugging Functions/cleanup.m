clear all
close all
delete(imaqfind);
imaqreset
delete(instrfind);
fclose('all');
delete(timerfindall)
clc
% beep,pause(.1),beep,pause(.1),beep
soundsc(sinc(3:.1:100)),soundsc(sinc(3:.1:100)),soundsc(sinc(3:.1:100))
