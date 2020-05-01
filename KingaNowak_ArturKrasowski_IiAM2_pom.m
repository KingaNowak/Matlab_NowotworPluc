function varargout = KingaNowak_ArturKrasowski_IiAM2_pom(varargin)
% KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM MATLAB code for KingaNowak_ArturKrasowski_IiAM2_pom.fig
%      KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM, by itself, creates a new KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM or raises the existing
%      singleton*.
%
%      H = KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM returns the handle to a new KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM or the handle to
%      the existing singleton*.
%
%      KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM.M with the given input arguments.
%
%      KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM('Property','Value',...) creates a new KINGANOWAK_ARTURKRASOWSKI_IIAM2_POM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before KingaNowak_ArturKrasowski_IiAM2_pom_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to KingaNowak_ArturKrasowski_IiAM2_pom_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help KingaNowak_ArturKrasowski_IiAM2_pom

% Last Modified by GUIDE v2.5 16-Apr-2020 01:41:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @KingaNowak_ArturKrasowski_IiAM2_pom_OpeningFcn, ...
                   'gui_OutputFcn',  @KingaNowak_ArturKrasowski_IiAM2_pom_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before KingaNowak_ArturKrasowski_IiAM2_pom is made visible.
function KingaNowak_ArturKrasowski_IiAM2_pom_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to KingaNowak_ArturKrasowski_IiAM2_pom (see VARARGIN)

% Choose default command line output for KingaNowak_ArturKrasowski_IiAM2_pom
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes KingaNowak_ArturKrasowski_IiAM2_pom wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = KingaNowak_ArturKrasowski_IiAM2_pom_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in poprzedni.
function poprzedni_Callback(hObject, eventdata, handles)
% hObject    handle to poprzedni (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global nrZdjecia
global liczba
global selpath
global zdjecie


nrZdjecia=nrZdjecia-1;

if nrZdjecia<1
    set(handles.poprzedni,'Enable','off');
elseif nrZdjecia==1
    axes(handles.obraz_wej)
    zdjecie=readimage(selpath,nrZdjecia);
    imshow(zdjecie)
    set(handles.poprzedni,'Enable','off');
else
    set(handles.poprzedni,'Enable','on');
    axes(handles.obraz_wej)
    zdjecie=readimage(selpath,nrZdjecia);
    imshow(zdjecie)
end


% --- Executes on button press in nastepny.
function nastepny_Callback(hObject, eventdata, handles)
% hObject    handle to nastepny (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global nrZdjecia
global selpath
global liczba
global zdjecie

nrZdjecia=1+nrZdjecia;

if nrZdjecia>liczba
    set(handles.nastepny,'Enable','off');
elseif nrZdjecia==liczba
    axes(handles.obraz_wej)
    zdjecie=readimage(selpath,nrZdjecia);
    imshow(zdjecie)
    set(handles.nastepny,'Enable','off');
else
    set(handles.poprzedni,'Enable','on');
    set(handles.nastepny,'Enable','on');
    axes(handles.obraz_wej)
    zdjecie=readimage(selpath,nrZdjecia);
    imshow(zdjecie)
end

% --- Executes on button press in baza.
function baza_Callback(hObject, eventdata, handles)
% hObject    handle to baza (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sciezka
sciezka = uigetdir;
if sciezka ~= ' '
    set(handles.poprzedni,'Visible','on');
    set(handles.nastepny,'Visible','on');
end
global selpath
selpath =imageDatastore(sciezka,'FileExtensions',{'.DCM','.dcm'},'ReadFcn',@dicomread);
global liczba
liczba=numpartitions(selpath);
global nrZdjecia
nrZdjecia=1;
if nrZdjecia<=1
    set(handles.poprzedni,'Enable','off');
elseif nrZdjecia>=liczba
    set(handles.nastepny,'Enable','off');
end
axes(handles.obraz_wej)
global zdjecie
zdjecie=readimage(selpath,1);
imshow(zdjecie)



% --- Executes on button press in zacznij.
function zacznij_Callback(hObject, eventdata, handles)
% hObject    handle to zacznij (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in przestrzen3D.
function przestrzen3D_Callback(hObject, eventdata, handles)
% hObject    handle to przestrzen3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
