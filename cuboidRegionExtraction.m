%drivingScenarioDesigner
%downsample + region extraction accuracy

clear
load sensorData.mat
carNum = 4;
timeNum = 16;
objNum = 7;

for t = 1 : timeNum
    car(1,t).ptcloudin = car0(t).PointClouds{1,1};
    car(2,t).ptcloudin = car1(t).PointClouds{1,1};
    car(3,t).ptcloudin = car2(t).PointClouds{1,1};
    car(4,t).ptcloudin = car3(t).PointClouds{1,1};
end

%coordinate transformation
for n = 1 : carNum
    for t = 1 : timeNum
        car(n,t).eul=[-car0(t).ActorPoses(n).Yaw/180*pi,0,0];
        car(n,t).trans= car0(t).ActorPoses(n).Position;
    end
end

for m = 1 : objNum
    for t = 1 : timeNum
        obj(m,t).eul=[-car0(t).ActorPoses(m+4).Yaw/180*pi,0,0];
        obj(m,t).trans= car0(t).ActorPoses(m+4).Position;
    end
end

for n = 1 : carNum    
    for t = 1 : timeNum
        car(n,t).rot=eul2rotm(car(n,t).eul); 
        car(n,t).tform = rigid3d(car(n,t).rot,car(n,t).trans);
        car(n,t).ptcloudout = pctransform(car(n,t).ptcloudin,car(n,t).tform);
%         figure
%         pcshow(car(n,t).ptcloudout)
%         pause(0.1)
    end
end


%load sensor.mat
detectorModel = HelperBoundingBoxDetector(...
    'XLimits',[0 130],...              % min-max
    'YLimits',[-20 20],...                % min-max
    'ZLimits',[-2 5],...                % min-max
    'SegmentationMinDistance',1,...   % minimum Euclidian distance
    'MinDetectionsPerCluster',2,...     % minimum points per cluster
    'MeasurementNoise',eye(7),...       % measurement noise in detection report
    'GroundMaxDistance',0.2);           % maximum distance of ground points from ground plane


% detectorModel = HelperBoundingBoxDetector(...
%     'XLimits',[0 120],...              % min-max
%     'YLimits',[-13 13],...                % min-max
%     'ZLimits',[0.2 5],...                % min-max
%     'SegmentationMinDistance',1.5,...   % minimum Euclidian distance
%     'MinDetectionsPerCluster',2,...     % minimum points per cluster
%     'MeasurementNoise',eye(7),...       % measurement noise in detection report
%     'GroundMaxDistance',0.1);           % maximum distance of ground points from ground plane

for t = 1 : timeNum
    merge(t).ptcloudout = car(1,t).ptcloudout;
    merge2(t).ptcloudout = car(1,t).ptcloudout;
    for n = 2 : carNum
        merge(t).ptcloudout = pcmerge(merge(t).ptcloudout,car(n,t).ptcloudout,0.00001); %high=0.01, low = 0.5
        merge2(t).ptcloudout = pcmerge(merge2(t).ptcloudout,car(n,t).ptcloudout,100); 
    end
end

for t = 8 : 8%timeNum
    ptcloudtest = merge(t).ptcloudout;
    ptcloudtest2 = merge2(t).ptcloudout;
%     figure
% %     pcshow(ptcloudtest2,'BackgroundColor',[1 1 1]);
%     ptped = select(ptcloudtest2, findPointsInsideCuboid(obj(5,t).cuboid, ptcloudtest2));
%     ptremove = select(ptcloudtest2, setdiff([1:ptcloudtest2.Count], findPointsInsideCuboid(obj(5,t).cuboid, ptcloudtest2)));
%     pcshow(ptremove,'BackgroundColor',[1 1 1]);

    [detections,obstacleIndices,groundIndices,croppedIndices] = detectorModel(ptcloudtest,t);
    ptcloudobstacle = select(ptcloudtest,obstacleIndices);
%     figure
%     pcshow(ptcloudobstacle,'BackgroundColor',[1 1 1]);
    for k = 1 : numel(detections)
          figure
          pcshow(ptcloudobstacle)
          hold on
          plot(detections{k,1}.Measurement')
          cuboidm = cuboidModel([detections{k,1}.Measurement(1:3)',detections{k,1}.Measurement(5:7)',0,0,detections{k,1}.Measurement(4)]);
%           plot3(detections{k,1}.Measurement(1),detections{k,1}.Measurement(2), detections{k,1}.Measurement(3),'o')
          plot(cuboidm);
          figure
           cubindices = findPointsInsideCuboid(cuboidm, ptcloudobstacle);
           ptcloudcuboid = select(ptcloudobstacle, cubindices);%findPointsInROI(ptcloudobstacle, findRoIbyCuboid(cuboidm)));
%           pcshow(ptcloudcuboid);
           eul=[-detections{k,1}.Measurement(4)/180*pi,0,0];
          trans= [0,0,0];%detections{k,1}.Measurement(1:3)';
          rot=eul2rotm(eul); 
          tform = rigid3d(rot,trans);
          ptcloudcuboidtrans = pctransform(ptcloudcuboid,tform);
          pcshow(ptcloudcuboidtrans);
%           [dd,ptcloudxz] = projectLidar(ptcloudcuboidtrans);
%           ddz  = length(find(dd==1))
    end
% %    pause(0.1)
end
save cuboidRegionExtraction.mat