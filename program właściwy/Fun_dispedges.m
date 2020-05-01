function [J2disp]=Fun_dispedges(J,obrys,Jmax)
%% LABORATORIUM PRZETWARZANIA OBRAZÓW
%% Pawe³ Badura 2009
%% 
%% Funkcja wyœwietlaj¹ca obraz J z obrysami po segmentacji (w kolorze)

% Obraz RGB - czerwona ramka
J(obrys)=0;     J2disp(:,:,2)=J;    J2disp(:,:,3)=J;
J(obrys)=Jmax;  J2disp(:,:,1)=J;        % by WW