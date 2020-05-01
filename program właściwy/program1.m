%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                              Ca³a baza zdjêæ                                                  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                         normalizacja wszytskich zdjêæ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% zbiór wszytskich zdjêæ
selpath =imageDatastore('C:\Users\kinga\Desktop\pom_program\baza_nowotworów\pacjent1\3.000000-CHEST  2.0  B50f  LUNG-38768','FileExtensions',{'.DCM','.dcm'}, 'ReadFcn',@dicomread);
liczba=numpartitions(selpath);
%zmienna wszytskich zdjêæ samych p³uc gray scale
str=struct('obraz',0);
%zmienna wszytskich zdjêæ po rozroscie obszaru czarno/bia³ych
strZmian=struct('obraz',0);
%pomocnicza przy rozroœcie i s¹siedztwie
strpom=struct('obraz',0);
%wybrane zdjêcie
n=40;
[wiersz,kolumna]=size(readimage(selpath,n));
for aktualne=1:liczba
    zd=im2double(readimage(selpath,aktualne));
    zdjMax=max(zd(:));
    zdjMin=min(zd(:));
    zd=imadjust(zd,[zdjMin zdjMax],[0 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                        Progowanie obrazu                                                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%potrzebne dane do pozosta³ych przekszta³ceñ
J=zd;
[w,k]=size(J);                              % w x k - rozmiary obrazu J
Jmin=min(min(J));    Jmax=max(max(J));      % skrajne wartoœci intensywnoœci w J
% Binaryzacja 
t=0.16;
Jw=zeros(w,k);
Jw(J>t)=1;
Jw(J<=t)=0;
% figure
% imshow(Jw);  xlabel('Obraz po binaryzacji');
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         Segmentowanie samych p³uc poszczególnych obrazów                                                  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% zalanie otworów cz.1
% tworzenie obrazu znaczników dla rekonstrukcji struktur brze¿nych
    marker = false(size(Jw));
    marker(1,:)=1;
    marker(end,:)=1;
    marker(:,1)=1;
    marker(:,end)=1;
    
% wywo³anie funkcji imreconstruct
    R = imreconstruct(marker,~Jw);
     
% wyliczenie obrazu otworów
    O = ~Jw-R;
  
% Modyfikacja umo¿liwiaj¹ca wykrycie i usuniêcie wszystkich (w tym nietypowych) otworów
    
% wywo³anie funkcji imreconstruct
   R = imreconstruct(marker,~Jw,4);
    
% wyliczenie obrazu otworów
     O = ~Jw-R;
%          figure
%     subplot(1,2,1); imshow(Jw,[]); title('Obraz wejsciowy');
%     subplot(1,2,2); imshow(O,[]); title('Obraz wysegmentowanych p³uc');
%% zalanie otworów cz.2 -> szukanie oskrzeli i potencjalnych zmian nowotworowych
% tworzenie obrazu znaczników dla rekonstrukcji struktur brze¿nych
    marker1 = false(size(O));
    marker1(1,:)=1;
    marker1(end,:)=1;
    marker1(:,1)=1;
    marker1(:,end)=1;
    
% wywo³anie funkcji imreconstruct
    R1 = imreconstruct(marker1,~O);
     
% wyliczenie obrazu otworów
    O1 = ~O-R1;  
% Modyfikacja umo¿liwiaj¹ca wykrycie i usuniêcie wszystkich (w tym nietypowych) otworów   
% wywo³anie funkcji imreconstruct
   R1 = imreconstruct(marker,~O,4);
    
% wyliczenie obrazu otworów
     O1 = ~O-R1;

orgpluca=zeros(wiersz,kolumna);
%     figure
%     subplot(1,2,1); imshow(O,[]); title('Obraz wejsciowy');
%     subplot(1,2,2); imshow(O1,[]); title('Obraz oskrzeli');
% orginalne p³uca
for i=1:wiersz
    for j=1:kolumna
        if O(i,j)==1 || O1(i,j)==1
            orgpluca(i,j)=zd(i,j);
        end
    end
end

    str(aktualne).obraz=orgpluca;
    strZmian(aktualne).obraz=zeros(w,k);
%     figure
%     subplot(2,2,1); imshow(Jw,[]); title('Obraz wejsciowy');
%     subplot(2,2,2); imshow(O,[]); title('Obraz wysegmentowanych p³uc');
%     subplot(2,2,3); imshow(O1,[]); title('Obraz oskrzeli');
%     subplot(2,2,4); imshow(orgpluca,[]); title('Obraz orginalnych p³uc');
% figure     
%     imshow(orgpluca,[]); title('Obraz orginalnych p³uc');
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                 szukanie zmian nowotworowych - rozrost
%                                 obszaru
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure()
imshow(str(n).obraz);
kryterium=1;                % kryterium przynale¿noœci do obszaru
                            %   1 - ró¿nica intensywnoœci w stosunku do 
                            %       punktu startowego
max_dJ=0.08;                 % maksymalna ró¿nica intensywnoœci 
sasiedztwo=8;               % typ s¹siedztwa
% Inicjalizacja
    Jd=double(str(n).obraz);
    Jsr2disp=[];                % wektor œrednich intensywnoœci
    l_pix=0;                    % licznik pikseli obiektu
    Jw=false(w,k);              % binarny obraz wynikowy
    Jw1=false(w,k);             % dodatkowa zmienna jak ta powy¿ej
    maska=false(w,k);           % pomocnicza macierz informuj¹ca czy ju¿ sprawdzono dany piksel
    %pobieranie po³o¿enia myszki(nawet kilku punktów) -> punktu startowego

    polozenie=drawpolyline();
    ss=polozenie.Position;
    X=int16(ss(:,1));
    Y=int16(ss(:,2));
    % zmienne na po³o¿enie centroidów w figurach
    centroidX=zeros(length(X),1);
    centroidY=zeros(length(Y),1);
    
for dana=1:length(X)
    s=[Y(dana,1),X(dana,1)];
    kolejka=s;                  % wstawienie do kolejki punktu startowego
    Jsr=Jd(Y(dana,1),X(dana,1));          % pierwotna (lub jedyna) œrednia intensywnoœæ obiektu
    

    
 % Procedura rozrostu obszaru
    tic;
    while (~isempty(kolejka))                   % pêtla g³ówna (max. 1s)
        c=kolejka(1,:);                         % punkt c ze szczytu kolejki do analizy
        kolejka=kolejka(2:size(kolejka,1),:);   % usuniêcie c z kolejki
        if (~maska(c(1),c(2)))                  % czy punkt nie by³ jeszcze analizowany?
            maska(c(1),c(2))=true;              % odznaczenie punktu c w masce, ...
            if (abs(Jd(c(1),c(2))-Jsr)<=max_dJ) % czy kryterium w³¹czenia jest spe³nione?
                Jw(c(1),c(2))=true;             % w³¹czenie punktu c do obiektu
                Jw1(c(1),c(2))=true;
                sasiedzi=Fun_neighbors(c,w,k,sasiedztwo);       % wyznaczenie indeksów s¹siadów punktu c
                kolejka=[   kolejka;
                            sasiedzi];          % wstawienie s¹siadów do kolejki
                l_pix=l_pix+1;                  % inkrementacja licznika pikseli
            end
        end
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                      Szukanie centroidu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[cenx,ceny]=ait_centroid(Jw1);
centroidX(dana,1)=int16(cenx);
centroidY(dana,1)=int16(ceny);
bie=str(n).obraz(centroidY(dana,1),centroidX(dana,1));
    if bie<0.2
                        %po³o¿enie s¹siedztwa
                strpom(1).obraz=[centroidY(dana,1)+1,centroidX(dana,1)];
                strpom(2).obraz=[centroidY(dana,1)-1,centroidX(dana,1)];
                strpom(3).obraz=[centroidY(dana,1),centroidX(dana,1)+1];
                strpom(4).obraz=[centroidY(dana,1),centroidX(dana,1)-1];
                strpom(5).obraz=[centroidY(dana,1)-1,centroidX(dana,1)-1];
                strpom(6).obraz=[centroidY(dana,1)+1,centroidX(dana,1)-1];
                strpom(7).obraz=[centroidY(dana,1)-1,centroidX(dana,1)+1];
                strpom(8).obraz=[centroidY(dana,1)+1,centroidX(dana,1)+1];
                pomocnicza=[str(n).obraz(centroidY(dana,1)+1,centroidX(dana,1)), str(n).obraz(centroidY(dana,1)-1,centroidX(dana,1)),str(n).obraz(centroidY(dana,1),centroidX(dana,1)+1), str(n).obraz(centroidY(dana,1),centroidX(dana,1)-1),str(n).obraz(centroidY(dana,1)-1,centroidX(dana,1)-1), str(n).obraz(centroidY(dana,1)+1,centroidX(dana,1)-1),str(n).obraz(centroidY(dana,1)-1,centroidX(dana,1)+1), str(n).obraz(centroidY(dana,1)+1,centroidX(dana,1)+1)];
                P=max(pomocnicza(:));
                if P>str(n).obraz(centroidY(dana,1),centroidX(dana,1))
                    [wp,kp]=find(pomocnicza==P);
                    centpom=strpom(kp).obraz;
                    centroidY(dana,1)=centpom(1,1);
                    centroidX(dana,1)=centpom(1,2);
                end
    end

Jw1=false(w,k);
maska=false(w,k);
end

strZmian(n).obraz=Jw;
figure()
z=Fun_dispedges(str(n).obraz,find(bwperim(imdilate(Jw,strel('disk',1)))),Jmax);
imshow(z,[]);   
xlabel('Obraz wraz z potencjalnymi zmianami nowotworowymi');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                 szukanie zmian nowotworowych - rozrost
%                                 obszaru na pozosta³ych zdjêciach w bazie
%                                 danych
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% od bie¿¹cego zdjêcia do ostatniego zdjêcia w bazie
% zmienne do aktualnego po³o¿enia centroidu
centroidXbie=centroidX;
centroidYbie=centroidY;
for d=1:length(centroidXbie)
    for i=n+1:liczba
        zdjecie=str(i).obraz;
        if zdjecie(centroidYbie(d,1),centroidXbie(d,1))<=0.15
            i=n+1;
            break;
        else
                %po³o¿enie s¹siedztwa
                strpom(1).obraz=[centroidYbie(d,1)+1,centroidXbie(d,1)];
                strpom(2).obraz=[centroidYbie(d,1)-1,centroidXbie(d,1)];
                strpom(3).obraz=[centroidYbie(d,1),centroidXbie(d,1)+1];
                strpom(4).obraz=[centroidYbie(d,1),centroidXbie(d,1)-1];
                strpom(5).obraz=[centroidYbie(d,1)-1,centroidXbie(d,1)-1];
                strpom(6).obraz=[centroidYbie(d,1)+1,centroidXbie(d,1)-1];
                strpom(7).obraz=[centroidYbie(d,1)-1,centroidXbie(d,1)+1];
                strpom(8).obraz=[centroidYbie(d,1)+1,centroidXbie(d,1)+1];
                pomocnicza=[zdjecie(centroidYbie(d,1)+1,centroidXbie(d,1)), zdjecie(centroidYbie(d,1)-1,centroidXbie(d,1)),zdjecie(centroidYbie(d,1),centroidXbie(d,1)+1), zdjecie(centroidYbie(d,1),centroidXbie(d,1)-1),zdjecie(centroidYbie(d,1)-1,centroidXbie(d,1)-1), zdjecie(centroidYbie(d,1)+1,centroidXbie(d,1)-1),zdjecie(centroidYbie(d,1)-1,centroidXbie(d,1)+1), zdjecie(centroidYbie(d,1)+1,centroidXbie(d,1)+1)];
                P=max(pomocnicza(:));
                if P>zdjecie(centroidYbie(d,1),centroidXbie(d,1))
                    [wp,kp]=find(pomocnicza==P);
                    centpom=strpom(kp).obraz;
                    centroidYbie(d,1)=centpom(1,1);
                    centroidXbie(d,1)=centpom(1,2);
                end
                Jd=double(zdjecie);
                kolejka1=[centroidYbie(d,1), centroidXbie(d,1)];
                Jsr=Jd(centroidYbie(d,1), centroidXbie(d,1));
                maska1=false(w,k);
                Jww=false(w,k);
                Jww1=false(w,k);
                tic;
              while(~isempty(kolejka1))
                    c=kolejka1(1,:);
                    kolejka1=kolejka1(2:size(kolejka1,1),:);
                    if (~maska1(c(1),c(2)))
                        maska1(c(1),c(2))=true;
                        if (abs(Jd(c(1),c(2))-Jsr)<=max_dJ)
                            Jww(c(1),c(2))=true;
                            Jww1(c(1),c(2))=true;
                            sasiedzi=Fun_neighbors(c,w,k,sasiedztwo);
                            kolejka1=[kolejka1;
                                    sasiedzi];
                            l_pix=l_pix+1;
                        end
                    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                      Szukanie centroidu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [cenx,ceny]=ait_centroid(Jww1);
                centroidXbie(d,1)=int16(cenx);
                centroidYbie(d,1)=int16(ceny);
                bie=str(i).obraz(centroidYbie(d,1),centroidXbie(d,1));
                if bie<0.2
                                   %po³o¿enie s¹siedztwa
                    strpom(1).obraz=[centroidYbie(d,1)+1,centroidXbie(d,1)];
                    strpom(2).obraz=[centroidYbie(d,1)-1,centroidXbie(d,1)];
                    strpom(3).obraz=[centroidYbie(d,1),centroidXbie(d,1)+1];
                    strpom(4).obraz=[centroidYbie(d,1),centroidXbie(d,1)-1];
                    strpom(5).obraz=[centroidYbie(d,1)-1,centroidXbie(d,1)-1];
                    strpom(6).obraz=[centroidYbie(d,1)+1,centroidXbie(d,1)-1];
                    strpom(7).obraz=[centroidYbie(d,1)-1,centroidXbie(d,1)+1];
                    strpom(8).obraz=[centroidYbie(d,1)+1,centroidXbie(d,1)+1];
                    pomocnicza=[zdjecie(centroidYbie(d,1)+1,centroidXbie(d,1)), zdjecie(centroidYbie(d,1)-1,centroidXbie(d,1)),zdjecie(centroidYbie(d,1),centroidXbie(d,1)+1), zdjecie(centroidYbie(d,1),centroidXbie(d,1)-1),zdjecie(centroidYbie(d,1)-1,centroidXbie(d,1)-1), zdjecie(centroidYbie(d,1)+1,centroidXbie(d,1)-1),zdjecie(centroidYbie(d,1)-1,centroidXbie(d,1)+1), zdjecie(centroidYbie(d,1)+1,centroidXbie(d,1)+1)];
                    P=max(pomocnicza(:));
                    if P>zdjecie(centroidYbie(d,1),centroidXbie(d,1))
                    [wp,kp]=find(pomocnicza==P);
                    centpom=strpom(kp).obraz;
                    centroidYbie(d,1)=centpom(1,1);
                    centroidXbie(d,1)=centpom(1,2);
                    end
                end
                Jww1=false(w,k);
                maska1=false(w,k);
                for ii=1:w
                    for jj=1:k
                        if Jww(ii,jj)==1 || strZmian(i).obraz(ii,jj)==1
                            Jww(ii,jj)=1;
                        end
                    end
                end
                strZmian(i).obraz=Jww;
           end
        end

    end
end
%% od bie¿¹cego zdjêcia do pierwszego zdjêcia w bazie
% zmienne do aktualnego po³o¿enia centroidu
centroidXbie=centroidX;
centroidYbie=centroidY;
for d=1:length(centroidXbie)
    for i=1:n-1
        zmienna=n-i;
        zdjecie=str(zmienna).obraz;
        if zdjecie(centroidYbie(d,1),centroidXbie(d,1))==0
            i=0;
            break;
        else
            przedzialp=(str(n).obraz(centroidY(d,1),centroidX(d,1))-0.05);
            przedzialm=(str(n).obraz(centroidY(d,1),centroidX(d,1))+0.05);
            znak=zdjecie(centroidYbie(d,1),centroidXbie(d,1));
            wyrazenie1=(znak>=przedzialp);
            wyrazenie2=(znak<=przedzialm);
            if wyrazenie1==1 && wyrazenie2==1 
                Jd=double(zdjecie);
                kolejka1=[centroidYbie(d,1), centroidXbie(d,1)];
                Jsr=Jd(centroidYbie(d,1), centroidXbie(d,1));
                maska1=false(w,k);
                Jww=false(w,k);
                Jww1=false(w,k);
                tic;
                while(~isempty(kolejka1))
                    c=kolejka1(1,:);
                    kolejka1=kolejka1(2:size(kolejka1,1),:);
                    if (~maska1(c(1),c(2)))
                        maska1(c(1),c(2))=true;
                        if (abs(Jd(c(1),c(2))-Jsr)<=max_dJ)
                            Jww(c(1),c(2))=true;
                            Jww1(c(1),c(2))=true;
                            sasiedzi=Fun_neighbors(c,w,k,sasiedztwo);
                            kolejka1=[kolejka1;
                                    sasiedzi];
                            l_pix=l_pix+1;
                        end
                    end
                end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                      Szukanie centroidu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [cenx,ceny]=ait_centroid(Jww1);
                centroidXbie(d,1)=int16(cenx);
                centroidYbie(d,1)=int16(ceny);
                Jww1=false(w,k);
                maska1=false(w,k);
                for ii=1:w
                    for jj=1:k
                        if Jww(ii,jj)==1 || strZmian(zmienna).obraz(ii,jj)==1
                            Jww(ii,jj)=1;
                        end
                    end
                end
                strZmian(zmienna).obraz=Jww;
                kolejka1=0;
            else
                i=0;
                break;
            end
        end

    end
end
