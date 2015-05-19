classdef asMarkerClass < handle
    
    
    properties (Access = private)        
        pos = [];   % marker positions
        axesHandles = [];
        
        ignoredDimensions = []; % dimensions where the position cell vector is 1
        markerHandles = {};
        selection = [];
        color = 'yellow';
    end
    
    methods (Access = public)
        function obj = asMarkerClass(selection, markerPositions)
            obj.selection = selection;
            if nargin > 1 && ~isempty(markerPositions)
                obj.pos = markerPositions;
            end
        end            
        
        function updateAxesHandles(obj, axesHandles)
            obj.axesHandles = axesHandles;
            obj.draw();
        end

        function add(obj, pos)
            if iscell(pos)
                disp('Marker positions cannot be cells yet');
                return;
            else
                % correct the common "input error", where pos is a row
                % rather than a column vector
                if isrow(pos)
                    pos = pos';
                end
                
                % store positions in the object properties
                obj.pos = [obj.pos, pos];
            end
            obj.draw();            
        end
        
        function pos = getPositions(obj)
            pos = obj.pos;
        end
        
        function markerHandle = getMarkerHandles(obj)
            markerHandle = obj.markerHandles;
        end
        
        function set(obj, pos)
            if nargin < 2
                pos = [];
            end
            if iscell(pos)
                % check the size of the cell array
                dataDims = obj.selection.getDimensions;
                siPos = size(pos);
                lPos = length(siPos);                                
                
                if lPos == length(dataDims)
                    % define all dimensions with size == 1 as
                    % "ignoredDimensions"
                    obj.ignoredDimensions = find(siPos == 1);
                    
                    % check for unequal dimensions
                    unequalDims = find(siPos ~= dataDims);
                    
                    % check, if the cell entries in the unequal dimensions
                    % are 1
                    if any(unequalDims ~= obj.ignoredDimensions)
                        error('lala');
                    end                    
                        
                else
                    % ok, the dimensions of the data and the position cell
                    % array are not equal. Check for the special case,
                    % where the position cell array is a vector and the
                    % data is 3d and thus can be assumed to be a stack of
                    % images...
                    if isvector(pos) && ...
                            length(dataDims) == 3 &&...
                            dataDims(3) == numel(pos)
                        pos = reshape(pos,[1,1,numel(pos)]);
                    else
                        error('lala');
                    end
                    
                end                                                            
            end
            
            % store positions in the object properties
            obj.pos = pos;            
            obj.draw();            
        end
        
        function clear(obj)
            for i = 1 : length(obj.markerHandles)                
                cellfun(@delete,obj.markerHandles{i});
            end
            obj.markerHandles = {};            
            obj.pos = [];
        end
        
        function draw(obj)           

            if isempty(obj.pos)
                return;
            end
            
            if iscell(obj.pos)
                % get selected frames
                S.subs = obj.selection.getValueAsCell(false);
                S.type = '()'; 
                
                % set selection in the ignored dimensions to 1
                S.subs(obj.ignoredDimensions) = repmat({1},[1,length(obj.ignoredDimensions)]);
                
                % get the marker positions for the selected frames
                selPos = squeeze(subsref(obj.pos,S));
                
                if length(selPos) ~= length(obj.axesHandles)
                    disp('Cannot show markers for the current dimensions');
                else
                    % loop over all axes and create the markers
                    nAxes = length(obj.axesHandles);
                    obj.markerHandles = cell(nAxes,1);
                    for i = 1 : nAxes
                        obj.markerHandles{i} = obj.drawAtAxes(obj.axesHandles(i), selPos{i});
                    end
                end
                
            else
                % we have positions for a single frame. Apply it on all
                % axes...
                
                nAxes = length(obj.axesHandles);
                obj.markerHandles = cell(nAxes);
                % ...loop over availables axes
                for i = 1 : nAxes
                    ah = obj.axesHandles(i);
                    obj.markerHandles{i} = obj.drawAtAxes(ah, obj.pos);
                end
            end
        end
    end
    
    methods (Access = protected)
        function markerHandles = drawAtAxes(obj, ah, pos)
            if isrow(pos)
                % correct the common "input error", where pos is a row
                % rather than a column vector
                pos = pos';
            end
            nMarkersPerAxes = size(pos,2);
            markerHandles = cell(nMarkersPerAxes,1);
            for i = 1 : nMarkersPerAxes
                P = pos(:,i);
%                 markerHandles{i} = impoint(ah,P(2),P(1),'color',obj.color);
                markerHandles{i} = impoint(ah,P(2),P(1));
            end
        end
    end
end