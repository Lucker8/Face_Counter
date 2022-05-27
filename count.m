function varargout = count(varargin)
% COUNT MATLAB code for count.fig
%      COUNT, by itself, creates a new COUNT or raises the existing
%      singleton*.
%
%      H = COUNT returns the handle to a new COUNT or the handle to
%      the existing singleton*.
%
%      COUNT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COUNT.M with the given input arguments.
%
%      COUNT('Property','Value',...) creates a new COUNT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before count_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to count_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%initialization
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @count_OpeningFcn, ...
                   'gui_OutputFcn',  @count_OutputFcn, ...
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



% --- Executes just before count is made visible.
function count_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to count (see VARARGIN)

% Choose default command line output for count
handles.output = hObject;
axes(handles.axes1);
imshow('blank.jpg');
axis off;
set(handles.text2,'string','0');

% Update handles structure
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = count_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global vid     % making the variable global
vid = videoinput('winvideo' , 1, 'YUY2_640X480');% Create a video input with YUY2 format and 640X480 resolution


% --- Executes on button press in count.
function count_Callback(hObject, eventdata, handles)
% hObject    handle to count (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global vid     

% Set the parameters for video
triggerconfig( vid ,'manual');                                      % the trigger occurs only after the trigger function
set(vid, 'FramesPerTrigger',1);                                     % one frame acquired per trigger
set(vid, 'TriggerRepeat',Inf);                                      % Keep executing the trigger every time the trigger condition is met until the stop function is called 
set(vid,'ReturnedColorSpace','rgb');                                % to get the rgb colour image 
vid.Timeout = 20;
start(vid);  

previous_faces=0;
previous_bodies = 0;
entered = 0;
left = 0;

facedetector = vision.CascadeObjectDetector;  
bodydetector =  vision.CascadeObjectDetector('Upperbody'); % Create a cascade detector object                                              

bodydetector.MinSize = [150 150];
facedetector.MinSize = [150 150];

while (isrunning(vid))

    trigger(vid); %trigger to get the frame from the video
    % make sure no errors at closing
    while(get(vid,'FramesAvailable')<1)
            unavailable = 1;
    end

image = getdata(vid); %store that frame in 'image'

bbox_face = step(facedetector, image);
bbox_body = step(bodydetector, image); % position of face in 'bbox' (x, y, width and height)
insert_object = insertObjectAnnotation(image,'rectangle',bbox_face,'MO');  % Draw the bounding box around the detected face.
imshow(insert_object);
axis off;                                                                   % invisible the axis from GUI
no_rows_face = size(bbox_face,1);
no_rows_body = size(bbox_body, 1);

% how many people are in
inside = sprintf('%d', (entered-left));

    % positive change in faces
     if (((no_rows_face - previous_faces)>0))
            entered = entered + (no_rows_face  - previous_faces);
            previous_faces= no_rows_face;
            previous_bodies = no_rows_body;
     end
     % negative change in faces
     if(((no_rows_face - previous_faces)<0))  
       if((no_rows_body - previous_bodies)>0)
            left = left + ((no_rows_body -no_rows_face));
            if((entered -left)< 0 )
                left = entered;
            end
            previous_bodies= no_rows_body;
        end
        if((no_rows_body - previous_bodies)<0)
            previous_bodies= no_rows_body;
        end
        previous_faces= no_rows_face;
     end
     % no change in faces
     if ((no_rows_face - previous_faces)==0)
        if((no_rows_body - previous_bodies)>0)
            left = left + (no_rows_body -no_rows_face);
            if((entered -left)< 0 )
                left = entered;
            end
            previous_bodies= no_rows_body;
        end
        if((no_rows_body - previous_bodies)<0)
            previous_bodies= no_rows_body;
         end
    end
    
set(handles.text2,'string',inside);                                              %display the value of inside in GUI

end



% --- Executes on button press in stop.
function stop_Callback(hObject, eventdata, handles)
% hObject    handle to stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global vid
stop(vid),clear vid %stop the running video
