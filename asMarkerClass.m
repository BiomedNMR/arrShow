classdef asMarkerClass < handle
    
    
    properties (Access = private)
        pos = [];   % marker positions
        axesHandles = [];
        
        ignoredDimensions = []; % dimensions where the position cell vector is 1
        markerHandles = {};
        selection = [];
        color = 'yellow';
        
        uiMenuHandle = []; % context menu handle
    end
    
    methods (Access = public)
        
        function obj = asMarkerClass(selection, markerPositions, uiMenuBase)
            obj.selection = selection;
            if nargin > 1 && ~isempty(markerPositions)
                obj.pos = obj.parsePos(markerPositions);
            end
            
            % populate ui menu
            obj.uiMenuHandle.base = uiMenuBase;
            obj.uiMenuHandle.showMarker = uimenu(uiMenuBase,'Label','Show' ,...
                'callback',@(src,evnt)obj.toggleVisibility(),...
                'checked','on');
            uimenu(uiMenuBase,'Label','Clear' ,...
                'callback',@(src,evnt)obj.clear(),'separator','on');
            
        end
        
        function updateAxesHandles(obj, axesHandles)
            obj.axesHandles = axesHandles;
            obj.draw();
        end
        
        function add(obj, pos)
            
            pos = obj.parsePos(pos);
            
            if iscell(obj.pos)
                if iscell(pos)
                    % if the new and the present positions are cell vectors
                    % of the same size: just combine them
                    if length(pos) ~= length(obj.pos)
                        error('lalala');
                    end
                    for i = 1 : length(pos)
                        obj.pos{i} = [obj.pos{i}, pos{i}];
                    end
                else
                    % if the present positions are cells and the new are
                    % not, add the new positions to all frames
                    for i = 1 : length(obj.pos)
                        obj.pos{i} = [obj.pos{i}, pos];
                    end
                end
            else
                % ..the present positions are not cells
                if iscell(pos)
                    for i = 1 : length(pos)
                        pos{i} = [obj.pos, pos{i}];
                    end
                    obj.pos = pos;
                else
                    obj.pos = [obj.pos, pos];
                end
            end
            obj.draw();
        end
        
        function bool = getVisibility(obj)
            bool = arrShow.onOffToBool(get(obj.uiMenuHandle.showMarker,'checked'));
        end
        
        function toggleVisibility(obj)
            bool = obj.getVisibility;
            obj.setVisibility(~bool);
        end
        
        function setVisibility(obj, toggle)
            set(obj.uiMenuHandle.showMarker,'checked', arrShow.boolToOnOff(toggle));
            if toggle
                obj.draw();
            else
                obj.deleteMarkers();
            end
        end
        
        function pos = get(obj)
            pos = obj.pos;
        end
        
        function addToCurrentFrames(obj, newPos)
            
            % assure that obj.pos is initialized as a cell array
            if ~iscell(obj.pos) || isempty(obj.pos)
                obj.initPosCellArray();           
            end

            % get the current positions in the current frames
            currPos = obj.getInCurrentFrames();
            
            % assure that the new positions are in a legal format
            expectedNumel = length(currPos);
            newPos = obj.parsePos(newPos, expectedNumel);
            
            
            if iscell(newPos)
                if length(currPos) ~= length(newPos)
                    disp('Length of the position cell vector has to match the number of selected frames');
                    return;
                end
                % add the new positions to all selected frames
                for i = 1 : length(currPos)
                    currPos{i} = [currPos{i}, newPos{i}];
                end
            else
                % add the the same new positions to all selected frames
                for i = 1 : length(currPos)
                    currPos{i} = [currPos{i}, newPos];
                end
            end
            
            
            % set the new positions
            obj.setInCurrentFrames(currPos, false);
            
        end
        
        function setInCurrentFrames(obj, newPos, parsePos)
            if nargin < 3 || isempty(parsePos)
                parsePos = true;
            end
            
            % assure that obj.pos is initialized as a cell array
            if ~iscell(obj.pos) || isempty(obj.pos)
                obj.initPosCellArray();           
            end                                   
            
            % get number of selected frames
            if parsePos
                expectedNumel = numel(obj.getInCurrentFrames());
                newPos = obj.parsePos(newPos, expectedNumel);
            end
            if ~iscell(newPos)
                newPos = {newPos};
            end            
            
            % get the subscripts for the selected frames
            S.subs = obj.selection.getValueAsCell(false);
            S.type = '()';            
            
            % set selection in the ignored dimensions to 1
            S.subs(obj.ignoredDimensions) = repmat({1},[1,length(obj.ignoredDimensions)]);
                                    
            % update the marker positions for the selected frames
            obj.pos = subsasgn(obj.pos,S,newPos);
            
            % "re-draw"
            obj.deleteMarkers()
            obj.draw();
            
        end
        
        function pos = getInCurrentFrames(obj)
            if iscell(obj.pos)
                % get selected frames
                S.subs = obj.selection.getValueAsCell(false);
                S.type = '()';
                
                % set selection in the ignored dimensions to 1
                S.subs(obj.ignoredDimensions) = repmat({1},[1,length(obj.ignoredDimensions)]);
                
                % get the marker positions for the selected frames
                pos = squeeze(subsref(obj.pos,S));
            else
                pos = obj.pos;
            end
        end
        
        function markerHandle = getMarkerHandles(obj)
            markerHandle = obj.markerHandles;
        end
        
        function set(obj, pos)
            if nargin < 2
                pos = [];
            end
            
            % parse and store positions in the object properties
            obj.pos = obj.parsePos(pos);
            obj.draw();
        end
        
        function clear(obj)
            % permanently removes all marker objects and positions
            obj.deleteMarkers();
            obj.pos = [];
        end
        
        function draw(obj)
            
            if isempty(obj.pos) || obj.getVisibility == false
                return;
            end
            
            if iscell(obj.pos)
                % get the marker positions for the selected frames
                selPos = obj.getInCurrentFrames();
                
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
    
    %     methods (Access = protected)
    %     end
    methods (Access = private)
        
        function initPosCellArray(obj)
            % try to initialize a position cell array assuming the colon
            % dimensions as "image dimensions" and all other dimensions as
            % frames
            
            
            if iscell(obj.pos) && ~isempty(obj.pos)
                error('obj.pos already seems to be initialized');
            end                                   
            
            % get the data size
            dataDims = obj.selection.getDimensions;
            
            % ignore the colon dimension by default
            obj.ignoredDimensions = obj.selection.getColonDims;
            dataDims(obj.ignoredDimensions) = 1;
            
            if isempty(obj.pos)
                obj.pos = cell(dataDims);
            else
                % duplicate the position to all cell entries
                tmpBackup = obj.pos;
                obj.pos = cell(dataDims);
                [obj.pos{:}] = deal(tmpBackup);
            end
        end
        
        function markerHandles = drawAtAxes(obj, ah, pos)
            nMarkersPerAxes = size(pos,2);
            markerHandles = cell(nMarkersPerAxes,1);
            for i = 1 : nMarkersPerAxes
                P = pos(:,i);
                %                 markerHandles{i} = impoint(ah,P(2),P(1),'color',obj.color);
                markerHandles{i} = impoint(ah,P(2),P(1));
            end
        end
        
        function deleteMarkers(obj)
            for i = 1 : length(obj.markerHandles)
                cellfun(@delete,obj.markerHandles{i});
            end
            obj.markerHandles = {};
        end
        
        function pos = parsePos(obj, pos, expectedNumel)
            % checks if the position vector matches the expected format.
            % If pos is a cell array and expectedNumel is empty, the array
            % is checked to match the data dimension.
            % If expectedNumel is give, the pos array is just checkt for
            % the correct number of elements.
            
            if iscell(pos)
                if nargin > 2 && ~isempty(expectedNumel)
                    if numel(pos) ~= expectedNumel
                        error('Number of elements in the new position vector are not valid');
                    end
                else
                
                    % check the size of the cell array
                    dataDims = obj.selection.getDimensions;
                    siPos = size(pos);
                    lPos = length(siPos);
                    lDat = length(dataDims);

                    if lPos < lDat
                        % padd all non given trailing dims with 1 to
                        % get equal siPos und dataDims vector size
                        siPos = [siPos, ones(1,lDat - lPos)];
                    end

                    % define all dimensions with size == 1 as
                    % "ignoredDimensions"
                    obj.ignoredDimensions = find(siPos == 1);

                    % check for unequal dimensions
                    unequalDims = find(siPos ~= dataDims);

                    % check, if the cell entries in the unequal dimensions
                    % are 1
                    if length(unequalDims) > length(obj.ignoredDimensions)||...
                        any(unequalDims ~= obj.ignoredDimensions)
                        % ok, the dimensions of the data and the position cell
                        % array are not equal. Check for the special case,
                        % where the position cell array is a vector and the
                        % data is 3d and thus can be assumed to be a stack of
                        % images...
                        if isvector(pos) && ...
                                length(dataDims) == 3 &&...
                                dataDims(3) == numel(pos)
                            pos = reshape(pos,[1,1,numel(pos)]);
                            obj.ignoredDimensions = [1,2];
                        else
                            error('Marker position vector has invalid dimensions');
                        end                                                                        
                    end
                end
                
                % assure that all antries are column vectors
                for i = 1 : length(pos)
                    if isrow(pos{i})
                        pos{i} = pos{i}';
                    end
                end
            else
                if isrow(pos)
                    pos = pos';
                end
            end
        end
    end
    
end