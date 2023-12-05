%Calculate Z_{n,m}^k data quality vector
clear
load cuboidRegionExtraction.mat
carbias = [1.3,0,0.7];
truckbias = [3.1,0,1.8];
pedbias = [0,0,0.9];
bycbias = [0,0,0.9];


carsize = [4.7,1.8,1.4];%volume11.8,peri area25.12
trucksize = [8.2,2.5,3.5];%71.7,115
pedsize = [0.24,0.45,1.7];%0.1836,2.56
bycsize = [1.7,0.45,1.7];%1.305,8.84
% 0.8: ped 25/136/9.7, by 125/96/14.14, car 576/48.81/22.92, truck 2000/27/17.39
% 0.9: 62/337/24.21,156/120/17.64, 700/59.32/27.86,3000/41.84/26.08
shapebias = [0.3,0.3,0];
for t = 1 : timeNum
    ptcloudtest = merge(t).ptcloudout;
%     figure
%     pcshow(ptcloudtest);
   
    obj(1,t).cuboid = cuboidModel([obj(1,t).trans+truckbias,trucksize+shapebias,0,0,-obj(1,t).eul(1)*180/pi]);
    obj(2,t).cuboid = cuboidModel([obj(2,t).trans+carbias,carsize+shapebias,0,0,-obj(2,t).eul(1)*180/pi]);
    obj(3,t).cuboid = cuboidModel([obj(3,t).trans+carbias,carsize+shapebias,0,0,-obj(3,t).eul(1)*180/pi]);
    obj(4,t).cuboid = cuboidModel([obj(4,t).trans+truckbias,trucksize+shapebias,0,0,-obj(4,t).eul(1)*180/pi]);
    obj(5,t).cuboid = cuboidModel([obj(5,t).trans+pedbias,pedsize+shapebias,0,0,-obj(4,t).eul(1)*180/pi]);
    obj(6,t).cuboid = cuboidModel([obj(6,t).trans+bycbias,bycsize+shapebias,0,0,-obj(4,t).eul(1)*180/pi]);
    obj(7,t).cuboid = cuboidModel([obj(7,t).trans+pedbias,pedsize+shapebias,0,0,-obj(4,t).eul(1)*180/pi]);
    
    car(1,t).cuboid = cuboidModel([car(1,t).trans+carbias,carsize+shapebias,0,0,-car(1,t).eul(1)*180/pi]);
    car(2,t).cuboid = cuboidModel([car(2,t).trans+carbias,carsize+shapebias,0,0,-car(2,t).eul(1)*180/pi]);
    car(3,t).cuboid = cuboidModel([car(3,t).trans+carbias,carsize+shapebias,0,0,-car(3,t).eul(1)*180/pi]);
    car(4,t).cuboid = cuboidModel([car(4,t).trans+carbias,carsize+shapebias,0,0,-car(4,t).eul(1)*180/pi]);

    objs(1).size = trucksize;
    objs(2).size = carsize;
    objs(3).size = carsize;
    objs(4).size = trucksize;
    objs(5).size = pedsize;
    objs(6).size = bycsize;
    objs(7).size = pedsize;
%     plot(obj(1,t).cuboid)
%     hold on
%     plot(obj(2,t).cuboid)
%     hold on
%     plot(obj(3,t).cuboid)
%     hold on
%     plot(obj(4,t).cuboid)
%     hold on
%     plot(obj(5,t).cuboid)
%     hold on
%     plot(obj(6,t).cuboid)
%     hold on
%     plot(obj(7,t).cuboid)
%     pause(0.1)
end



%feature vector
fdim = 2;
for t = 1 : timeNum
%     figure
%     pcshow(merge(t).ptcloudout);
    for m = 1 : objNum
        odx = obj(m,t).cuboid.Dimensions(1)/fdim;
        ody = obj(m,t).cuboid.Dimensions(2)/fdim;
        odz = obj(m,t).cuboid.Dimensions(3)/fdim;
        ocx = obj(m,t).cuboid.Center(1);
        ocy = obj(m,t).cuboid.Center(2);
        ocz = obj(m,t).cuboid.Center(3);
        for i = 1 : fdim 
             for j = 1 : fdim
                 for k = 1 : fdim
%                      px = ocx + (-(fdim-1)/2^(fsqrt+1)+1/fdim*(i-1))*odx*fdim;
%                      py = ocy + (-(fdim-1)/2^(fsqrt+1)+1/fdim*(j-1))*ody*fdim;
%                      pz = ocz + (-(fdim-1)/2^(fsqrt+1)+1/fdim*(k-1))*odz*fdim;
                     px = ocx + (-(fdim-1)/(2*fdim)+1/fdim*(i-1))*odx*fdim;
                     py = ocy + (-(fdim-1)/(2*fdim)+1/fdim*(j-1))*ody*fdim;
                     pz = ocz + (-(fdim-1)/(2*fdim)+1/fdim*(k-1))*odz*fdim;
                     obj(m,t).partition(i,j,k).cuboid = cuboidModel([px,py,pz, odx, ody, odz, obj(m,t).cuboid.Orientation]);
%                       hold on
%                       plot(obj(m,t).partition(i,j,k).cuboid)  
                 end
             end
        end
    end
end

for t = 1 : timeNum
        for m = 1 : objNum
            merge(t).obj(m).ptcloud = select(merge(t).ptcloudout, findPointsInsideCuboid(obj(m,t).cuboid, merge(t).ptcloudout));
%             figure
%             plot(obj(m,t).cuboid);
%            figure
%             pcshow(merge(t).obj(m).ptcloud,'BackgroundColor',[1 1 1]);
%             xlim([13.5 22.5])
%             zlim([0 5])
            for n = 1 : carNum
                car(n,t).obj(m).ptcloud = select(car(n,t).ptcloudout, findPointsInsideCuboid(obj(m,t).cuboid, car(n,t).ptcloudout));
%                 figure 
%                 pcshow(car(n,t).ptcloudout,'BackgroundColor',[1 1 1]);
%                 hold on
%                 plot(obj(m,t).cuboid);
% %                 hold on
% %                 plot(car(n,t).cuboid);
%                 
% 
% %                 figure
% %                  pcshow(car(2,8).obj.ptcloud,'BackgroundColor',[1 1 1]);

 


            end
            
            for i = 1 : fdim
                for j = 1 : fdim
                    for k = 1 : fdim
%                         merge(t).obj(m).feature(1+(i-1)+(j-1)*fdim+(k-1)*fdim^2) = numel(findPointsInsideCuboid(obj(m,t).partition(i,j,k).cuboid, merge(t).ptcloudout));
                        merge(t).obj(m).feature(i,j,k) = numel(findPointsInsideCuboid(obj(m,t).partition(i,j,k).cuboid, merge(t).ptcloudout));
                        for n = 1 : carNum
%                             car(n,t).obj(m).feature(1+(i-1)+(j-1)*fdim+(k-1)*fdim^2) =  numel(findPointsInsideCuboid(obj(m,t).partition(i,j,k).cuboid, car(n,t).ptcloudout));
                            car(n,t).obj(m).feature(i,j,k) =  numel(findPointsInsideCuboid(obj(m,t).partition(i,j,k).cuboid, car(n,t).ptcloudout));
%                             hold on
%                             plot(obj(m,t).partition(i,j,k).cuboid)  
                        end
                    end
                end
            end
        end
end

save dataQualityVectorExtraction.mat