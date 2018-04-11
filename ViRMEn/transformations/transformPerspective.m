function coords2D = transformPerspective(coords3D)

s = 1;
p = 1;

scr = get(0,'screensize');
aspectRatio = scr(3)/scr(4);

coords2D = zeros(size(coords3D));

coords2D(1,:) = s*coords3D(1,:)./coords3D(2,:);
coords2D(2,:) = s*coords3D(3,:)./coords3D(2,:);
coords2D(3,:) = true;


f = coords3D(2,:)<=0;
coords2D(3,f) = false;
coords2D(1,f) = p*sign(coords3D(1,f))*aspectRatio;
coords2D(2,f) = p*sign(coords3D(3,f));

f = find(abs(coords2D(1,:))>aspectRatio);
coords2D(1,f) = p*sign(coords2D(1,f))*aspectRatio;
coords2D(3,f) = false;

f = find(abs(coords2D(2,:))>1);
coords2D(2,f) = p*sign(coords2D(2,f));
coords2D(3,f) = false;