%% --- USER PARAMETERS ---
filename = 'test7.4';

% time interval to analyze (minutes:seconds)
t_start = 32*60 + 5;   % 1:35
t_end   = 85*60 + 5;   % 3:55

% Physical constants
Cp_water = 4186; % J/(kg*C)
rho_water = 1;   % kg/L (approximation valid for water)

%% --- FILE READING ---
fileID = fopen(filename, 'r');
time_sec = []; T_Amb = []; T_In = []; T_Out = []; Flow = []; Press = [];

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

%% --- THERMAL POWER CALCULATION ---
% Instantaneous temperature difference
DeltaT = T_Out - T_In;

% Mass flow rate in kg/s (L/min * 1 kg/L / 60 s)
m_dot = (Flow .* rho_water) / 60;

% Instantaneous power (Watt)
Power = m_dot .* Cp_water .* DeltaT;

% Mean power only when flow exists (avoid errors if Flow = 0)
if any(Flow > 0)
    mean_power = mean(Power(Flow > 0));
else
    mean_power = 0;
end

%% --- AVERAGE FLOW AND POWER EVERY 5 POINTS ---
N = 5;  
Flow_avg = []; Power_avg = []; time_avg = [];

for k = 1:N:length(Flow)-N+1
    Flow_avg(end+1)  = mean(Flow(k:k+N-1));
    Power_avg(end+1) = mean(Power(k:k+N-1));
    time_avg(end+1)  = mean(time_min(k:k+N-1));
end

%% --- PLOT ---
figure('Name','Thermal Analysis and Power');

subplot(1,1,1)
plot(time_avg, Power_avg, 'm-s', 'LineWidth', 1.5);
xlabel('Time (min)');
ylabel('Power (W)');
grid on;
title(['Average Thermal Power: ', num2str(mean_power, '%.2f'), ' W']);

%% --- RESULTS DISPLAY ---
disp(['--- RESULTS IN THE INTERVAL ---']);
disp(['Average flow: ', num2str(mean(Flow), '%.3f'), ' L/min']);
disp(['Average DeltaT: ', num2str(mean(DeltaT), '%.2f'), ' °C']);
disp(['Calculated average power: ', num2str(mean_power, '%.2f'), ' W']);