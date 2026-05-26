%% --- USER PARAMETERS ---
filename = 'nonfunziona';

% time interval to analyze (minutes:seconds)
t_start = 3*60 + 35;   % 3:35
t_end   = 85*60 + 55;  % 85:55

%% --- FILE READING ---
fileID = fopen(filename, 'r');

time_sec = [];
T_Amb = [];
T_In = [];
T_Out = [];
Flow = [];
Press = [];

while ~feof(fileID)
    line = fgetl(fileID);
    
    if ischar(line) && startsWith(line, '[')
        data = sscanf(line, '[%d:%d] T_Amb: %f C, T_In: %f C, T_Out: %f C, Flow: %f L/min, Press: %f bar');
        
        if length(data) == 7
            time_sec(end+1) = data(1)*60 + data(2);
            T_Amb(end+1)    = data(3);
            T_In(end+1)     = data(4);
            T_Out(end+1)    = data(5);
            Flow(end+1)     = data(6);
            Press(end+1)    = data(7);
        end
    end
end

fclose(fileID);

%% --- TIME FILTER ---
idx = (time_sec >= t_start) & (time_sec <= t_end);

time_sec = time_sec(idx);
T_Amb = T_Amb(idx);
T_In = T_In(idx);
T_Out = T_Out(idx);
Flow = Flow(idx);
Press = Press(idx);

time_min = time_sec / 60;

%% --- FLOW AVERAGE EVERY 5 POINTS ---
N = 5;  % number of points per average

Flow_avg = [];
time_avg = [];

for k = 1:N:length(Flow)-N+1
    Flow_avg(end+1) = mean(Flow(k:k+N-1));
    time_avg(end+1) = mean(time_min(k:k+N-1));
end

%% --- PLOT ---
figure('Name','Data Analysis');

% --- Temperatures ---
subplot(2,1,1)
plot(time_min, T_Amb, 'LineWidth', 1.5); hold on;
plot(time_min, T_In, 'LineWidth', 1.5);
plot(time_min, T_Out, 'LineWidth', 1.5);

xlabel('Time (min)');
ylabel('Temperature (°C)');
title('Temperature');
legend('T_{Amb}', 'T_{In}', 'T_{Out}');
grid on;

% --- Averaged flow ---
subplot(2,1,2)
plot(time_avg, Flow_avg, 'o-', 'LineWidth', 1.5);

xlabel('Time (min)');
ylabel('Flow (L/min)');
title('Flow (average every 5 points)');
grid on;

%% --- TOTAL MEAN FLOW (optional) ---
mean_flow = mean(Flow);
disp(['Mean flow in interval: ', num2str(mean_flow), ' L/min']);