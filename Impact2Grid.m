clear all
load income
ypc = income ./ Population;
load temperature

%%
intercept = -13.33;
incpar = 1.68021*0.947868562;
tempar = -0.448468;

impact = intercept + incpar*log(ypc) + tempar*Temperature;

%%
for i = 1:size(GDL),
    disp(i)
    [z, r]= vec2mtx(GDL(i).Y,GDL(i).X,Res,[-90 90],[-180 180]); %z == 1 if border
    y = z; %fill in
    for j=2:359,
        for k=2:719,
            if z(j,k)==0 & sum(z(1:j-1,k))>0 & sum(z(j+1:360,k))>0 & sum(z(j,1:k-1))>0 & sum(z(j,k+1:720))>0
                y(j,k) = 1;
            end
        end
    end
    ir0 = impact.*y;
    ir1 = impact.*income.*y;
    impactreguw(i) = sum(nansum(ir0))/sum(sum(y)); %unweighted average
    impactregion(i) = sum(nansum(ir1))/sum(sum(income.*y)); %weighted average
end

%%
importImpact

%% add field to structure
GDL(1).impact = 0;
GDL(1).natimp = 0;
GDL(1).impactuc = 0;

for i=1:size(GDL),
    GDL(i).impact = RegionsS3.impact2(RegionsS3.GDLcode==GDL(i).GDLcode);
    GDL(i).natimp = RegionsS3.natimp1(RegionsS3.GDLcode==GDL(i).GDLcode);
    GDL(i).impactuc = impactregion(i);
end

%%
for i=1:size(GDL),
    if ~isempty(GDL(i).impact) & ~isinf(GDL(i).impactuc)
        check(i)  = (GDL(i).impact-GDL(i).impactuc);
    end
end

%%
impcorr = zeros(360,720);
natimp = zeros(360,720);
for i = 1:size(GDL),
    disp(i)
    [z, r]= vec2mtx(GDL(i).Y,GDL(i).X,Res,[-90 90],[-180 180]);
    y = z;
    for j=2:359,
        for k=2:719,
            if z(j,k)==0 & sum(z(1:j-1,k))>0 & sum(z(j+1:360,k))>0 & sum(z(j,1:k-1))>0 & sum(z(j,k+1:720))>0
                y(j,k) = 1;
            end
        end
    end
    if ~isnan(check(i)),
        impcorr  = impcorr + check(i)*(y - 0.5*z);
    end
    if ~isempty(GDL(i).natimp),
        natimp = natimp + GDL(i).natimp*(y - 0.5*z);
    end
end

%%
impact(isinf(-impact))=NaN;
impactc = impact+impcorr;
C = zeros(NLat,NLong,3);
C(:,:,1) = (impactc < 0).*impactc/min(min(impactc));
C(:,:,2) = (impactc > 0).*impactc/max(max(impactc));
%mesh(Long,Lat,impactc,C,'EdgeColor','interp')
mesh(Long,Lat,impactc)

%%
natimpv = reshape(natimp,[NLat*NLong 1]);
impactv = reshape(impactc,[NLat*NLong 1]);
popv = reshape(Population,[NLat*NLong 1]);
incomev = reshape(income,[NLat*NLong 1]);
toExcel = [popv incomev impactv natimpv];

%there appears to be an outlier in income.*natimp