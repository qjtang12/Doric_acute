clear all

% setting parameters
samplerate=120; % in unit of Hz, 120 Hz is how it is saved when select 100 downsampling when saving.
epoc=300; % manually enter this accordingly
t_minus=180; % time before time point 0, unit in second
t_plus=180; % time after time point 0, unit in secon
n_chn=4;  % how many animals
t_off=0; % the video is 10s ahead of the recording

% load data 
[filename,path] = uigetfile('*.csv');
cd(path);
[data, names] = loadData(filename);
data(isnan(data))=0;
%% organized the detrended data
x=transpose(1:size(data,1));
x_total=transpose(1:size(data,1));
data_dtr=data;

n_session=size(epoc,1);
epoc_corrected=epoc-t_off;

for n=1:n_session
    for i=1:n_chn
        [val,t0]=min(abs(data(:,1)-epoc_corrected(n,i)));
        t_low=t0-t_minus*samplerate+1;
        t_high=t0+t_plus*samplerate;
        data_org(:,i*2-1:i*2,n)=data_dtr(t_low:t_high,i*3-1:i*3);
    end
end

% detrend 465 by 405 and calculate z score
for n=1:n_session
    for i=1:n_chn
        y_405=data_org(:,i*2-1,n);
        y_465=data_org(:,i*2,n);
        fit_405_temp=polyfit(y_405,y_465,1); %linear fitting 405 to 465
        fit_405_curve(:,i,n)=fit_405_temp(1)*y_405+fit_405_temp(2);
        data_detrend(:,i,n)=y_465-fit_405_curve(:,i,n);
        data_zscore(:,i,n)=(data_detrend(:,i,n)-mean(data_detrend(1:15*samplerate,i,n)))./std(data_detrend(1:15*samplerate,i,n));
    end
end

for n=1:n_chn
    data_zscore_down(:,n,:)=downsample(squeeze(data_zscore(:,n,:)),samplerate./10);
end

% save important data
save (filename(1:end-5),'data_org','data_zscore');
% export results to excel
[dim1,dim2,dim3]=size(data_zscore_down);
for n=1:n_chn
    results(:,(n-1)*dim3+1+(n-1)*1:n*dim3+(n-1)*1)=num2cell(squeeze(data_zscore_down(:,n,:)));
end

title = strcat( filename(1:end-4),'_results');
xlswrite( title ,results, 1 ) ;

%% this is for exponential detrending, don't run this if you don't need to, you processed data was already saved above
y=0; %place holder, place your data manually
%%
[dim1,dim2]=size(y);
x=transpose([1:dim1]);

for n=1:dim2
    range=max(y(1:600,n))-min(y(1:600,n));
    expfit = @(n,x) n(1).*exp(n(2).*x)+n(3);
        n0=[range;-1;0];
        fit_temp(:,n)=lsqcurvefit(expfit,n0,x(1:900),y(1:900,n));
        y_dtr(:,n)=y(:,n)-expfit(fit_temp(:,n),x);
end