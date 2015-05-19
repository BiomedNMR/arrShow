classdef asPixelMarkClass < handle
    
    
    properties (Access = private)        
        pos = [];   % marker positions
        axesHandles = [];
        selection = [];
        
        updFigCb = [];
    end
    
    methods (Access = public)
        function obj = asPixelMarkClass(updFigCb, markerPositions)
            obj.updFigCb = updFigCb;
            if nargin > 1 && ~isempty(markerPositions)
                obj.pos = markerPositions;
            end
        end            
        
        function updateHandlesAndSelection(obj, axesHandles, selection)
            obj.axesHandles = axesHandles;
            obj.selection = selection;
            obj.drawMarkers();
        end
        
        function createMarker(obj, pos)
            if iscell(obj.pos)
                disp('implement me');
            else
                obj.pos = pos;
            end
            obj.drawMarkers();            
        end
        
        function drawMarkers(obj)
            disp('implement me');
        end
    end
end