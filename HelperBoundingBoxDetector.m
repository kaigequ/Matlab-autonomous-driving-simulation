classdef HelperBoundingBoxDetector < matlab.System
    % HelperBoundingBoxDetector A helper class to segment the point cloud
    % into bounding box detections.
    % The step call to the object does the following things:
    %
    % 1. Removes point cloud outside the limits.
    % 2. From the survived point cloud, segments out ground
    % 3. From the obstacle point cloud, forms clusters and puts bounding
    %    box on each cluster.
    
    % Cropping properties
    properties
        % XLimits XLimits for the scene
        XLimits = [0 120];
        % YLimits YLimits for the scene
        YLimits = [-13 13];
        % ZLimits ZLimits fot the scene
        ZLimits = [0.2 5];

    end
   
    % Ground Segmentation Properties
    properties
        % GroundMaxDistance Maximum distance of point to the ground plane
        GroundMaxDistance = 0.1;
        % GroundReferenceVector Reference vector of ground plane
        GroundReferenceVector = [0 0 1];
        % GroundMaxAngularDistance Maximum angular distance of point to reference vector
        GroundMaxAngularDistance = 5;
    end
    
    % Bounding box Segmentation properties
    properties
        % SegmentationMinDistance Distance threshold for segmentation
        SegmentationMinDistance = 1;%1.6;
        % MinDetectionsPerCluster Minimum number of detections per cluster
        MinDetectionsPerCluster = 2;%2;
        % MaxZDistanceCluster Maximum Z-coordinate of cluster
        MaxZDistanceCluster = 5;
        % MinZDistanceCluster Minimum Z-coordinate of cluster
        MinZDistanceCluster = -5;
    end
    
    % Ego vehicle radius to remove ego vehicle point cloud.
    properties
        % EgoVehicleRadius Radius of ego vehicle
        EgoVehicleRadius = 3;
    end
    
%     properties
%         % Barrier Position and Radius 
%         Barrier1End1 = [58.3260, 26.3840, 0];
%         Barrier1End2 = [-0.1740, -33.8160, 0];
%         Barrier2End1 = [50.4740, 34.0160, 0];
%         Barrier2End2 = [-8.0260, -26.1840, 0];
%         BarrierRadius = 3;
%     end

    properties
        % MeasurementNoise Measurement noise for the bounding box detection
        MeasurementNoise = blkdiag(eye(3),10,eye(3));
    end
    
    properties (Nontunable)
        MeasurementParameters = struct.empty(0,1);
    end
    
    methods 
        function obj = HelperBoundingBoxDetector(varargin)
            setProperties(obj,nargin,varargin{:})
        end
    end
    
    methods (Access = protected)
        function [bboxDets,obstacleIndices,groundIndices,croppedIndices] = stepImpl(obj,currentPointCloud,time)
            % Crop point cloud
            [pcSurvived,survivedIndices,croppedIndices] = cropPointCloud(currentPointCloud,obj.XLimits,obj.YLimits,obj.ZLimits,obj.EgoVehicleRadius);
            % Remove ground plane
            [pcObstacles,obstacleIndices,groundIndices] = removeGroundPlane(pcSurvived,obj.GroundMaxDistance,obj.GroundReferenceVector,obj.GroundMaxAngularDistance,survivedIndices);
            % Form clusters and get bounding boxes
            detBBoxes = getBoundingBoxes(pcObstacles,obj.SegmentationMinDistance,obj.MinDetectionsPerCluster,obj.MaxZDistanceCluster,obj.MinZDistanceCluster);
            % Assemble detections
            if isempty(obj.MeasurementParameters)
                measParams = {};
            else
                measParams = obj.MeasurementParameters;
            end
            bboxDets = assembleDetections(detBBoxes,obj.MeasurementNoise,measParams,time);
        end
    end
end
    
function detections = assembleDetections(bboxes,measNoise,measParams,time)
% This method assembles the detections in objectDetection format.
numBoxes = size(bboxes,2);
detections = cell(numBoxes,1);
for i = 1:numBoxes
    detections{i} = objectDetection(time,cast(bboxes(:,i),'double'),...
        'MeasurementNoise',double(measNoise),'ObjectAttributes',struct,...
        'MeasurementParameters',measParams);
end
end

function bboxes = getBoundingBoxes(ptCloud,minDistance,minDetsPerCluster,maxZDistance,minZDistance)
    % This method fits bounding boxes on each cluster with some basic
    % rules.
    % Cluster must have at least minDetsPerCluster points.
    % Its mean z must be between maxZDistance and minZDistance.
    % length, width and height are calculated using min and max from each
    % dimension.
    [labels,numClusters] = pcsegdist(ptCloud,minDistance);
    pointData = ptCloud.Location;
    bboxes = nan(7,numClusters,'like',pointData);
    isValidCluster = false(1,numClusters);
    for i = 1:numClusters
        thisPointData = pointData(labels == i,:);
        meanPoint = mean(thisPointData,1);
        %if size(thisPointData,1) > minDetsPerCluster && meanPoint(3) < maxZDistance && meanPoint(3) > minZDistance
            cuboid = pcfitcuboid(pointCloud(thisPointData));
            yaw = cuboid.Orientation(3);
            L = cuboid.Dimensions(1);
            W = cuboid.Dimensions(2);
            H = cuboid.Dimensions(3);
%             if abs(yaw) > 45
%                 possibles = yaw + [-90;90];
%                 [~,toChoose] = min(abs(possibles));
%                 yaw = possibles(toChoose);
%                 temp = L;
%                 L = W;
%                 W = temp;
%             end
            bboxes(:,i) = [cuboid.Center yaw L W H]';
            isValidCluster(i) = true; %L < 10 & W < 5 & H > 1 & H< 5;
       %end
    end
    bboxes = bboxes(:,isValidCluster);
end

function [ptCloudOut,obstacleIndices,groundIndices] = removeGroundPlane(ptCloudIn,maxGroundDist,referenceVector,maxAngularDist,currentIndices)
    % This method removes the ground plane from point cloud using
    % pcfitplane.
    [~,groundIndices,outliers] = pcfitplane(ptCloudIn,maxGroundDist,referenceVector);%maxAngularDist);
    ptCloudOut = select(ptCloudIn,outliers);
    obstacleIndices = currentIndices(outliers);
    groundIndices = currentIndices(groundIndices);

%     ptCloudOut = ptCloudIn;
%     obstacleIndices = currentIndices;
%     groundIndices = [];
end

function [ptCloudOut,indices,croppedIndices] = cropPointCloud(ptCloudIn,xLim,yLim,zLim,egoVehicleRadius)
    % This method selects the point cloud within limits and removes the
    % ego vehicle point cloud using findNeighborsInRadius
    locations = ptCloudIn.Location;
    locations = reshape(locations,[],3);
    locationSize = size(locations, 1);
    insideX = locations(:,1) < xLim(2) & locations(:,1) > xLim(1);
    insideY = locations(:,2) < yLim(2) & locations(:,2) > yLim(1);
    insideZ = locations(:,3) < zLim(2) & locations(:,3) > zLim(1);
    inside = insideX & insideY & insideZ;
    
    % Remove ego vehicle
%     nearIndices = findNeighborsInRadius(ptCloudIn,[0 0 0],egoVehicleRadius);
%     nonEgoIndices = true(ptCloudIn.Count,1);
%     nonEgoIndices(nearIndices) = false;

    %Remove barrier
%     Barrier1End1 = [58.3260, 26.3840, 0];
%     Barrier1End2 = [-0.1740, -33.8160, 0];
%     Barrier2End1 = [50.4740, 34.0160, 0];
%     Barrier2End2 = [-8.0260, -26.1840, 0];
%     BarrierRadius = 1;
%     Barrier1Indices = vecnorm(cross(repmat(Barrier1End2-Barrier1End1,locationSize,1)', (locations-repmat(Barrier1End1,locationSize, 1))'))/norm(Barrier1End2-Barrier1End1) > BarrierRadius;
%     Barrier2Indices = vecnorm(cross(repmat(Barrier2End2-Barrier2End1,locationSize,1)', (locations-repmat(Barrier2End1,locationSize, 1))'))/norm(Barrier2End2-Barrier2End1) > BarrierRadius;

    %Filter
    %size(inside)
    %size(Barrier1Indices)
    validIndices = inside; % & Barrier1Indices' & Barrier2Indices'; % & nonEgoIndices;
    indices = find(validIndices);
    croppedIndices = find(~validIndices);
    ptCloudOut = select(ptCloudIn,indices);
end
