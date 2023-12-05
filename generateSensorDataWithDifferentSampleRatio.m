clear
load trainVoxnet.mat
%generate more spatial diverse test data
dNum = 10;
for d = 1 : dNum
    for m = 1 : objNum
        if m == 1 | m == 4
            shape = trucksize;
            cateId = 1;
        end
        if m == 2 | m == 3
            shape = carsize;
            cateId = 2;
        end
        if m == 5 | m == 7  
            shape = pedsize;
            cateId = 3;
        end
        if m == 6
            shape = bycsize;
            cateId = 4;
        end
         for t = 1 : timeNum
            ptCloudout = pcdownsample(merge(t).obj(m).ptcloud,'random',d/dNum);
            ptTrain((d-1)*objNum*timeNum+(m-1)*timeNum+t).ptcloud = ptCloudout;
            grid = pcbin(ptCloudout,[gs gs gs]);
            occupancyGrid = zeros(size(grid),'single');
            for ii = 1:numel(grid)
                occupancyGrid(ii) = ~isempty(grid{ii});
            end
            occArray_Train_D(:,:,:,1,(d-1)*objNum*timeNum+(m-1)*timeNum+t) =  occupancyGrid;
            cateidArray_Train_D((d-1)*objNum*timeNum+(m-1)*timeNum+t,1) = cateId;
            ptnumArray_Train_D((d-1)*objNum*timeNum+(m-1)*timeNum+t,1) =  ptCloudout.Count;
            varArray_Train_D((d-1)*objNum*timeNum+(m-1)*timeNum+t,1) = max(var(ptCloudout.Location));
            shapeArray_Train_D((d-1)*objNum*timeNum+(m-1)*timeNum+t,:) = shape;

            for i = 1 : fdim
                for j = 1 : fdim
                    for k = 1 : fdim
                         featureArray_Train_D(i,j,k,1,(d-1)*objNum*timeNum+(m-1)*timeNum+t)  = numel(findPointsInsideCuboid(obj(m,t).partition(i,j,k).cuboid, ptCloudout));
                    end
                end
            end

            for n = 1 : carNum
                ptCloudout = pcdownsample(car(n,t).obj(m).ptcloud,'random',d/dNum);
                ptTest((d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n).ptcloud = ptCloudout;
                cateidArray_Test_D((d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n,1) = cateId;
                ptnumArray_Test_D((d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n,1) =  ptCloudout.Count;
                shapeArray_Test_D((d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n,:) = shape;
                for i = 1 : fdim
                    for j = 1 : fdim
                        for k = 1 : fdim
                             featureArray_Test_D(i,j,k,1,(d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n)  = numel(findPointsInsideCuboid(obj(m,t).partition(i,j,k).cuboid, ptCloudout));
                        end
                    end
                end
                if ptCloudout.Count > 1
                    grid = pcbin(ptCloudout,[gs gs gs]);
                    occupancyGrid = zeros(size(grid),'single');
                    for ii = 1:numel(grid)
                        occupancyGrid(ii) = ~isempty(grid{ii});
                    end
                    occArray_Test_D(:,:,:,1,(d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n) =  occupancyGrid;
                    varArray_Test_D((d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n,1) =  max(var(ptCloudout.Location));
                else
                    occArray_Test_D(:,:,:,1,(d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n) =  zeros(gs,gs,gs);
                    varArray_Test_D((d-1)*objNum*timeNum*carNum+(m-1)*timeNum*carNum+(t-1)*carNum + n,1) =  0;
                end
            end
    
        end
    end
end


ptnumArray_D = [ptnumArray_Test_D; ptnumArray_Train_D];
varArray_D = [varArray_Test_D; varArray_Train_D];
shapeArray_D = [shapeArray_Test_D; shapeArray_Train_D];
featureArray_D = cat(5, featureArray_Test_D, featureArray_Train_D);
occArray_D = cat(5, occArray_Test_D, occArray_Train_D);
cateidArray_D = [cateidArray_Test_D; cateidArray_Train_D];




save generateSensorDataWithDifferentSampleRatio.mat