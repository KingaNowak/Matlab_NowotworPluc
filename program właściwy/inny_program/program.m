%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             wybrane zdjêcie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             normalizacja                                                     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% potrzebne zmienne/ wgranie zdjêcia
% zdjêcie, na którym zaznaczamy zmiany
numerZdj=33;
naz='82945.DCM';
A=im2double(dicomread(naz));
Amax=max(A(:));
[wiersz, kolumna]=size(A);
A1=A;
for i=1:wiersz
    for j=1:kolumna
        A1(i,j)=A(i,j)/Amax;
    end
    
end
figure
imshow(A1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                          Progowanie obrazu                                                    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%potrzebne dane do pozosta³ych przekszta³ceñ
J=A1;
[w,k]=size(J);                              % w x k - rozmiary obrazu J
Jmin=min(min(J));    Jmax=max(max(J));      % skrajne wartoœci intensywnoœci w J
% Binaryzacja 
t=0.16;
Jw=zeros(w,k);
Jw(J>t)=1;
Jw(J<=t)=0;
figure
imshow(Jw);  xlabel('Obraz po binaryzacji');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                      Segmentowanie samych p³uc                                                   %%
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

    figure
    subplot(1,2,1); imshow(Jw,[]); title('Obraz wejsciowy');
    subplot(1,2,2); imshow(O,[]); title('Obraz wysegmentowanych p³uc');

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
     
    figure
    subplot(1,2,1); imshow(O,[]); title('Obraz wejsciowy');
    subplot(1,2,2); imshow(O1,[]); title('Obraz oskrzeli');

orgpluca=zeros(wiersz,kolumna);
% orginalne p³uca
for i=1:wiersz
    for j=1:kolumna
        if O(i,j)==1 || O1(i,j)==1
            orgpluca(i,j)=A1(i,j);
        end
    end
end
    
figure
    subplot(2,2,1); imshow(Jw,[]); title('Obraz wejsciowy');
    subplot(2,2,2); imshow(O,[]); title('Obraz wysegmentowanych p³uc');
    subplot(2,2,3); imshow(O1,[]); title('Obraz oskrzeli');
    subplot(2,2,4); imshow(orgpluca,[]); title('Obraz orginalnych p³uc');
figure     
    imshow(orgpluca,[]); title('Obraz orginalnych p³uc');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                 szukanie zmian nowotworowych - rozrost
%                                 obszaru
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kryterium=1;                % kryterium przynale¿noœci do obszaru
                            %   1 - ró¿nica intensywnoœci w stosunku do 
                            %       punktu startowego
max_dJ=0.08;                 % maksymalna ró¿nica intensywnoœci 
sasiedztwo=8;               % typ s¹siedztwa
% Inicjalizacja
    Jd=double(orgpluca);
    Jsr2disp=[];                % wektor œrednich intensywnoœci
    l_pix=0;                    % licznik pikseli obiektu
    Jw=false(w,k);              % binarny obraz wynikowy
    Jw1=false(w,k);             % dodatkowa zmienna jak ta powy¿ej
    maska=false(w,k);           % pomocnicza macierz informuj¹ca czy ju¿ sprawdzono dany piksel
    %pobieranie po³o¿enia myszki(nawet kilku punktów) -> punktu startowego

    polozenie=drawpolyline();
    ss=polozenie.Position;
    ss=int16(ss);
    X=ss(:,1);
    Y=ss(:,2);
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
Jw1=false(w,k);
maska=false(w,k);
end
figure()
z=Fun_dispedges(orgpluca,find(bwperim(imdilate(Jw,strel('disk',1)))),Jmax);
imshow(z,[]);   
xlabel('Obraz wraz z potencjalnymi zmianami nowotworowymi');
      
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%                                              Ca³a baza zdjêæ                                                  %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                                        szukaniezmian nowotworowych w 3D
% %                                        i normalizacja wszytskich zdjêæ
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % zbiór wszytskich zdjêæ
% selpath =imageDatastore('C:\Users\kinga\Desktop\pom_program\bie¿acy_folder_z_programem_82910.DCM','FileExtensions',{'.DCM','.dcm'}, 'ReadFcn',@dicomread);
% liczba=numpartitions(selpath);
% str=struct('obraz',0);
% strZmian=struct('obraz',0);
% for n=1:liczba
%     zd=im2double(readimage(selpath,n));
%     zdjMax=max(zd(:));
%     for i=1:wiersz
%         for j=1:kolumna
%                 zd(i,j)=zd(i,j)/zdjMax;
%         end
%     end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                                        Progowanie obrazu                                                    
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %potrzebne dane do pozosta³ych przekszta³ceñ
% J=zd;
% [w,k]=size(J);                              % w x k - rozmiary obrazu J
% Jmin=min(min(J));    Jmax=max(max(J));      % skrajne wartoœci intensywnoœci w J
% % Binaryzacja 
% t=0.16;
% Jw=zeros(w,k);
% Jw(J>t)=1;
% Jw(J<=t)=0;
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                         Segmentowanie samych p³uc poszczególnych obrazów                                                  %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% zalanie otworów cz.1
% % tworzenie obrazu znaczników dla rekonstrukcji struktur brze¿nych
%     marker = false(size(Jw));
%     marker(1,:)=1;
%     marker(end,:)=1;
%     marker(:,1)=1;
%     marker(:,end)=1;
%     
% % wywo³anie funkcji imreconstruct
%     R = imreconstruct(marker,~Jw);
%      
% % wyliczenie obrazu otworów
%     O = ~Jw-R;
%   
% % Modyfikacja umo¿liwiaj¹ca wykrycie i usuniêcie wszystkich (w tym nietypowych) otworów
%     
% % wywo³anie funkcji imreconstruct
%    R = imreconstruct(marker,~Jw,4);
%     
% % wyliczenie obrazu otworów
%      O = ~Jw-R;
% %% zalanie otworów cz.2 -> szukanie oskrzeli i potencjalnych zmian nowotworowych
% % tworzenie obrazu znaczników dla rekonstrukcji struktur brze¿nych
%     marker1 = false(size(O));
%     marker1(1,:)=1;
%     marker1(end,:)=1;
%     marker1(:,1)=1;
%     marker1(:,end)=1;
%     
% % wywo³anie funkcji imreconstruct
%     R1 = imreconstruct(marker1,~O);
%      
% % wyliczenie obrazu otworów
%     O1 = ~O-R1;  
% % Modyfikacja umo¿liwiaj¹ca wykrycie i usuniêcie wszystkich (w tym nietypowych) otworów   
% % wywo³anie funkcji imreconstruct
%    R1 = imreconstruct(marker,~O,4);
%     
% % wyliczenie obrazu otworów
%      O1 = ~O-R1;
% 
% orgpluca=zeros(wiersz,kolumna);
% % orginalne p³uca
% for i=1:wiersz
%     for j=1:kolumna
%         if O(i,j)==1 || O1(i,j)==1
%             orgpluca(i,j)=zd(i,j);
%         end
%     end
% end
% 
%     str(n).obraz=orgpluca;
%     strZmian(n).obraz=zeros(w,k);
% end
% 
% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                                 szukanie zmian nowotworowych - rozrost
% %                                 obszaru na pozosta³ych zdjêciach w bazie
% %                                 danych
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % zmienne do aktualnego po³o¿enia centroidu
% centroidXbie=centroidX;
% centroidYbie=centroidY;
% % rozrost obszaru na pozosta³ych zdjêciach
% for d=1:length(centroidX)
%     for o=numerZdj:liczba
%         zdjecie=str(o).obraz; 
%         if zdjecie(centroidXbie(d,1),centroidYbie(d,1))>=orgpluca(centroidXbie(d,1),centroidYbie(d,1))-0.08 && zdjecie(centroidXbie(d,1),centroidYbie(d,1))<=orgpluca(centroidXbie(d,1),centroidYbie(d,1))+0.08
%             Jd=double(zdjecie);
%             kolejka1=[centroidYbie(d,1),centroidXbie(d,1)];                  % wstawienie do kolejki punktu startowego
%             Jsr=Jd(centroidYbie(d,1),centroidXbie(d,1));          % pierwotna (lub jedyna) œrednia intensywnoœæ obiektu
%             maska1=false(w,k);
%             Jww=false(w,k);
%             Jww1=false(w,k);             % dodatkowa zmienna jak ta powy¿ej
% 
%             % Procedura rozrostu obszaru
%                 tic;
%                 while (~isempty(kolejka1))                              % pêtla g³ówna (max. 1s)
%                         c=kolejka1(1,:);                                   % punkt c ze szczytu kolejki do analizy
%                         kolejka1=kolejka1(2:size(kolejka1,1),:);           % usuniêcie c z kolejki
%                         if(~maska1(c(1),c(2)))                             % czy punkt nie by³ jeszcze analizowany?
%                             maska1(c(1),c(2))=true;                        % odznaczenie punktu c w masce, ...
%                             if(abs(Jd(c(1),c(2))-Jsr)<=max_dJ)             % czy kryterium w³¹czenia jest spe³nione?
%                                 Jww(c(1),c(2))=true;                       % w³¹czenie punktu c do obiektu
%                                 Jww1(c(1),c(2))=true;
%                                 sasiedzi=Fun_neighbors(c,w,k,sasiedztwo);  % wyznaczenie indeksów s¹siadów punktu c
%                                 kolejka1=[   kolejka1;
%                                             sasiedzi];                     % wstawienie s¹siadów do kolejki
%                                 l_pix=l_pix+1;                             % inkrementacja licznika pikseli  
%                             end
%                         end
%                 end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                                      Szukanie centroidu
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             [cenx,ceny]=ait_centroid(Jww1);
%             centroidXbie(d,1)=int16(cenx);
%             centroidYbie(d,1)=int16(ceny);
%             Jww1=false(w,k);
%             maska=false(w,k);
%             for i=1:w
%                 for j=1:k
%                     if Jww(w,k)==1 || strZmian(o).obraz(w,k)==1
%                         Jww(w,k)=1;
%                     end
%                 end
%             end
%             strZmian(o).obraz=Jww;
%             figure()
%             imshow(strZmian(o).obraz); 
%         else
%             o=numerZdj;
%             break;
%         end
%     end
% end
% %%
% % zmienne do aktualnego po³o¿enia centroidu
% centroidXbie=centroidX;
% centroidYbie=centroidY;
% for d=1:length(centroidX)
%     for o=numerZdj-1:1
%         zdjecie=str(o).obraz; 
%         if zdjecie(centroidXbie(d,1),centroidYbie(d,1))>=orgpluca(centroidXbie(d,1),centroidYbie(d,1))-0.08 && zdjecie(centroidXbie(d,1),centroidYbie(d,1))<=orgpluca(centroidXbie(d,1),centroidYbie(d,1))+0.08
%             Jd=double(zdjecie);
%             kolejka1=[centroidYbie(d,1),centroidXbie(d,1)];                  % wstawienie do kolejki punktu startowego
%             Jsr=Jd(centroidYbie(d,1),centroidXbie(d,1));          % pierwotna (lub jedyna) œrednia intensywnoœæ obiektu
%             maska1=false(w,k);
%             Jww=false(w,k);
%             Jww1=false(w,k);
%             % Procedura rozrostu obszaru
%                 tic;
%                 while (~isempty(kolejka1))                              % pêtla g³ówna (max. 1s)
%                         c=kolejka1(1,:);                                   % punkt c ze szczytu kolejki do analizy
%                         kolejka1=kolejka1(2:size(kolejka1,1),:);           % usuniêcie c z kolejki
%                         if(~maska1(c(1),c(2)))                             % czy punkt nie by³ jeszcze analizowany?
%                             maska1(c(1),c(2))=true;                        % odznaczenie punktu c w masce, ...
%                             if(abs(Jd(c(1),c(2))-Jsr)<=max_dJ)             % czy kryterium w³¹czenia jest spe³nione?
%                                 Jww(c(1),c(2))=true;                       % w³¹czenie punktu c do obiektu
%                                 Jww1(c(1),c(2))=true;
%                                 sasiedzi=Fun_neighbors(c,w,k,sasiedztwo);  % wyznaczenie indeksów s¹siadów punktu c
%                                 kolejka1=[   kolejka1;
%                                             sasiedzi];                     % wstawienie s¹siadów do kolejki
%                                 l_pix=l_pix+1;                             % inkrementacja licznika pikseli  
%                             end
%                         end
%                 end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                                      Szukanie centroidu
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             [cenx,ceny]=ait_centroid(Jww1);
%             centroidXbie(d,1)=int16(cenx);
%             centroidYbie(d,1)=int16(ceny);
%             Jww1=false(w,k);
%             maska=false(w,k);
%             for i=1:w
%                 for j=1:k
%                     if Jww(w,k)==1 || strZmian(o).obraz(w,k)==1
%                         Jww(w,k)=1;
%                     end
%                 end
%             end    
%             strZmian(o).obraz=Jww;
%             figure()
%             imshow(strZmian(o).obraz); 
%         else
%             o=numerZdj;
%             break;
%         end
%     end
% end
