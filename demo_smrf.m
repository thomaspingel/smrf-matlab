% Test SMRF against ISPRS data set.

% Download reference LIDAR data if not in temp or current dir
if ~exist([tempdir,'\','samp11.txt']) & ~exist('samp11.txt')
    disp('Downloading data.');
    url = 'http://www.itc.nl/isprswgIII-3/filtertest/Reference.zip';
    fn = 'Reference.zip';
    urlwrite(url,[tempdir,'\',fn]);
    unzip([tempdir,'\',fn], tempdir);
end

%%
% Read data
M = dlmread([tempdir,'\samp11.txt']);
x = M(:,1);
y = M(:,2);
z = M(:,3);
gobs = M(:,4);  % 0 is Ground, 1 is Object
clear M;

% Declare parameters for this sample (Pingel et al., 2011)
c = 1;
s = .2;
w = 16;
et = .45;
es = 1.2;

% Run filter
[ZI R gest] = smrf(x,y,z,'c',c,'s',s,'w',w,'et',et,'es',es);

% Report results
ct = crosstab(gobs,gest)

%%
ti = 50;
hfig = figure;
plot3(x,y,z,'.','markersize',4);
axis equal vis3d
% axis([min(x) max(x) min(y) max(y) min(z) max(z)]);
daspect([1 1 1]);
set(gca,'xtick',[min(x):ti:max(x)]);
set(gca,'ytick',[min(y):ti:max(y)]);
set(gca,'ztick',[min(z):ti:max(z)]);
set(gca,'xticklabel',{[0:50:max(x)-min(x)]});
set(gca,'yticklabel',{[0:50:max(y)-min(y)]});
set(gca,'zticklabel',{[0:50:max(z)-min(z)]});
figDPI = '600';
figW = 5;
figH = 5;
grid on
set(gca,'fontsize',8)
set(hfig,'PaperUnits','inches');
set(hfig,'PaperPosition',[0 0 figW figH]);
fileout = ['vcs-smrf-samp11-dotview.'];
print(hfig,[fileout,'tif'],'-r600','-dtiff');
print(hfig,[fileout,'png'],'-r600','-dpng'); 
%%
ti = 50;
hfig = figure;
colormap gray;
[xi yi] = ir2xiyi(ZI,R);
[XI YI] = meshgrid(xi,yi);
surf(XI,YI,ZI,hillshade2(ZI),'edgecolor','none');
% surf(ZI,hillshade2(ZI),'edgecolor','none');
axis equal vis3d;
% axis([min(x) max(x) min(y) max(y) min(z) max(z)]);
daspect([1 1 1]);
set(gca,'xtick',[min(x):ti:max(x)]);
set(gca,'ytick',[min(y):ti:max(y)]);
set(gca,'ztick',[min(z):ti:max(z)]);
set(gca,'xticklabel',{[0:50:max(x)-min(x)]});
set(gca,'yticklabel',{[0:50:max(y)-min(y)]});
set(gca,'zticklabel',{[0:50:max(z)-min(z)]});
view(3);
set(hfig,'PaperUnits','inches');
set(hfig,'PaperPosition',[0 0 figW figH]);
set(hfig,'PaperPosition',[0 0 figW figH]);
set(gca,'fontsize',8)
fileout = ['vcs-smrf-samp11-demview.'];
print(hfig,[fileout,'tif'],'-r600','-dtiff');
print(hfig,[fileout,'png'],'-r600','-dpng'); 
