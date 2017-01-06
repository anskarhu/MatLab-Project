close all;
clear all;
Sig1 = load('100.txt');%LOAD signals


    Sig1_fft = fft(Sig1(:, 2));%From timedomain to freq domain
     %DT = Sig1(2,1) - Sig1(1,1);
     Dif_vect = diff(Sig1(:,1));%time between samples is not constant
     figure;
     plot(Dif_vect)
     title('Time between samples')
     DT = mean(Dif_vect);%Averaging gives us time between samples     
     % sampling frequency
     Fs = 1/DT
     DF = Fs/size(Sig1,1)
     freq = 0:DF:Fs/2;
     Sig1_fft = Sig1_fft(1:length(Sig1_fft)/2+1);
     figure;
     subplot(2,1,1);
     plot(freq,20*log10(abs(Sig1_fft)));
     title('Original frequency domain signal')

     
%Noise occurs at 55.5Hz, filter out 55.4-55.7, also 111Hz is filtered
[b,a] = butter(2,[59.5, 60.5]/(Fs/2),'stop');%Create filters
%fvtool(b,a)
[d,c] = butter(10,100/(Fs/2),'low');
[f,e] = butter(1,0.5/(Fs/2),'high') %removes the baseline
Sig1Filter = filter(b,a,Sig1);%perform filtering
Sig1Filter = filter(d,c,Sig1Filter);
Sig1Filter = filter(f,e,Sig1Filter);

    Sig1filt_fft = fft(Sig1Filter(:, 2)); %plot filtered freq domain signal 
     % sampling frequency
     Fs2 = 1/DT
     DF2 = Fs2/size(Sig1Filter,1)
     freq = 0:DF2:Fs2/2;
     Sig1filt_fft = Sig1filt_fft(1:length(Sig1filt_fft)/2+1);
     subplot(2,1,2)
     plot(freq,20*log10(abs(Sig1filt_fft)));
     title('Filtered frequency domain signal')
          

     
%PEAK DETECTOR

%{
windowed = 0; %This option is not working properly, so constant value is used
for i=1:1000:length(Sig1Filter(:,2))-1000
    window = Sig1Filter(i:i+1000, 2);
    for k=1:100
        windowed(i,k) = window(k);
    end
end  

for i=1:1000:length(Sig1Filter(:,2))-2000
    minimums(i) = min(windowed(i)); 
end
mean_min = mean(minimums);
%PeakTHD = mean_min*0.5; 
%}
 %{
%This option didnt work either. This one would have been the best in my
opinion.
Sig1Filter_PKS_ov05(1) = 0;
PKS_ov05LOCS(1) = 0;
for l = 1000:1000:length(Sig1Filter(:,2))
    window = Sig1Filter(l-999:l, 2);
    PeakTHD = mean(abs(window))*2;
    [pks,locs] = findpeaks(window,(l-999:l),'MinPeakHeight',PeakTHD, 'MinPeakWidth', 0.01, 'MinPeakDistance',0.3);
    Sig1Filter_PKS_ov05(end+1:end+length(pks)) = pks;
    PKS_ov05LOCS(end+1:end+length(locs)) = locs;
end
Sig1Filter_PKS_ov05 = Sig1Filter_PKS_ov05(2:end);
PKS_ov05LOCS = PKS_ov05LOCS(2:end);
%}

PeakTHD = 0.5; %Didnt get threshold windowing working proprely, so 
                %used temporary threshold value

               
[Sig1Filter_PKS_ov05,PKS_ov05LOCS] = findpeaks(Sig1Filter(:, 2), Sig1(:, 1), 'MinPeakHeight',PeakTHD, 'MinPeakWidth', 0.01, 'MinPeakDistance',0.3); %COUNT PEAKS THAT ARE OVER threshold;
Numb_of_PKS_over = numel(Sig1Filter_PKS_ov05)

%Plot filtered time domain signal and peak finder
figure;
plot(Sig1(:, 1), Sig1Filter(:, 2)) 
hold on
plot (PKS_ov05LOCS, Sig1Filter_PKS_ov05, 'o')
title('Filtered signal and peak detector')


%Count differences between peak locations( RR-interval)
for j = 2:length(PKS_ov05LOCS)
    R_R_Interval(j-1) = PKS_ov05LOCS(j) - PKS_ov05LOCS(j-1);
end
PKS_ov05LOCS = PKS_ov05LOCS(1: end-1);
figure;
subplot(2,1,1)
plot(PKS_ov05LOCS, R_R_Interval)
ylabel('RR-interval[s]')

    
%POINCARE plot, plots (xt, xt+1),then plots(xt+1, xt+2),then (xt+2, xt+3)..
figure;
plot(R_R_Interval(1:end-1),R_R_Interval(2:end), '.')
title('Poincare Plot')
xlabel('RR (n)')
ylabel('RR (n-1)')
%Used for loop (below) first to perform poincare, but to make it faster changed it
%to above
%{
for i = 1:(length(R_R_Interval)-1)
    plot(R_R_Interval(i),R_R_Interval(i+1), '.')
    hold on;
end
%}



%Arrhythmic beat classification
RR_Category = ones(length(R_R_Interval),1);
for i=2:length(R_R_Interval)-1 
    RR_Category(i) = 1;
    RR1 = R_R_Interval(i-1);
    RR2 = R_R_Interval(i);
    RR3 = R_R_Interval(i+1);
    
    %%Rule1 = VF Beat classification
    if RR2 < 0.6 && 1.8*RR2 < RR1;
        RR_Category(i) = 3;
            
        for k=i+1:length(R_R_Interval)-1
            RR1k = R_R_Interval(k-1);
            RR2k = R_R_Interval(k);
            RR3k = R_R_Interval(k+1);
            if (RR1k < 0.7 && RR2k < 0.7 && RR3k < 0.7)||...
                    (RR1k + RR2k + RR3k < 1.7)
                RR_Category(i) = 3; 
            %end
            else % Not arrhythm  
                if i > 4 && (RR_Category(i-4) == 1 && RR_Category(i-3) == 3 &&...
                    RR_Category(i-2) == 3 && RR_Category(i-1) == 3)
                    RR_Category(i-1) = 1;
                    RR_Category(i-2) = 1;
                    RR_Category(i-3) = 1; %Sequentially Cat3 less than 4--> Classified to Cat1 
           %{         
            RR_Cat3 = find (RR_Category = 3); 
                if RR_Cat3 < 4
                    RR_Category = 1;
                end
            %}
                end
            end
        end
    end

    %RULE2 = PVC
    
    if ((1.15*RR2 < RR1) && (1.15*RR2 < RR3)) ||...
            ((abs(RR1-RR2) < 0.3) && ((RR1 < 0.8) && (RR2 < 0.8)) && (RR3 > 1.2*((RR1+RR2)/2))) ||...
            ((abs(RR2-RR3) < 0.3) && ((RR2 < 0.8) && (RR3 < 0.8)) && (RR1 > 1.2*((RR1+RR2)/2)))
        %}
        RR_Category(i) = 2;
    end
    
        
    %RULE3 = 2degree heart block beats
    if (2.2 < RR2 && RR2 < 3.0) && (abs(RR1-RR2) < 0.2 || abs(RR2-RR3) < 0.2)
        RR_Category(i) = 4;
    end
    
end    
figure;
plot(PKS_ov05LOCS,RR_Category, 'x')
title('Arrhythmic Beat Classification')
ylim([0 5]);  


%Additional features.

%Plot HR, in test point of view
HR = (60./R_R_Interval);
subplot(2,1,2)
plot(PKS_ov05LOCS,HR)
ylabel('Heart Rate ppm')

%AVG HR
HR_TOT = 0;
for t = 1:length(HR)
    HR_TOT = HR_TOT + HR(t);
end
AVG_HR = HR_TOT/length(HR)

%AVG R-R
AVG_R_R = mean(R_R_Interval)

%standard deviation
StDev_HR = std(HR)
StDev_R_R = std(R_R_Interval)

