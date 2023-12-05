function [] = showCloudWithoutPed(pt, objCub)

ptped = select(pt, findPointsInsideCuboid(objCub, pt));
ptremove = select(pt, setdiff([1:pt.Count], findPointsInsideCuboid(objCub, pt)));
 pcshow(ptremove,'BackgroundColor',[1 1 1]);
%select(merge(t).ptcloudout, findPointsInsideCuboid(obj(7,t).cuboid, pt))
end