%% --- FLOW RECONSTRUCTION SCRIPT FROM THERMAL BALANCE ---
filename = 'nonfunziona';

% 1. SELECT TIME INTERVAL (where the Flow sensor was stuck at 0)
t_start = 30*60 + 35;   
t_end   = 55*60 + 55;   

% 2. ASSUMED POWER INPUT (based on previous tests)
% If you previously calculated 105W, use that value.
P_target = 120; % Watt

% Constants
Cp_water = 4186; 
rho_water = 1;

%% --- DATA READING AND FILTERING ---
fileID = fopen(filename, 'r');
time_sec = []; T_In = []; T_Out = []; Flow_sensor = [];

while ~feof(fileID)
    line = fgetl(fileID);
    if ischar(line) && startsWith(line, '[')
        data = sscanf(line, '[%d:%d] T_Amb: %f C, T_In: %f C, T_Out: %f C, Flow: %f L/min');
        if length(data) >= 6
            time_sec(end+1) = data(1)*60 + data(2);
            T_In(end+1)     = data(4);
            T_Out(end+1)    = data(5);
            Flow_sensor(end+1) = data(6);
        end
    end
end
fclose(fileID);

idx = (time_sec >= t_start) & (time_sec <= t_end);
T_In_sub = T_In(idx);
T_Out_sub = T_Out(idx);
time_min_sub = time_sec(idx)/60;

%% --- REVERSE FLOW CALCULATION ---
% Instantaneous temperature difference
dT = T_Out_sub - T_In_sub;

% Filter unrealistic or very small Delta T values (sensor noise)
dT_clean = dT;
dT_clean(dT < 0.2) = NaN; % If dT < 0.2, calculation becomes unstable

% mass flow rate (kg/s) = P / (Cp * dT)
m_dot_est = P_target ./ (Cp_water .* dT_clean);

% Flow (L/min) = m_dot * 60
Flow_estimated = m_dot_est * 60;

% Final average value
mean_flow_est = nanmean(Flow_estimated);

%% --- VISUALIZATION ---
figure('Name', 'Flow Reconstruction');

subplot(2,1,1)
plot(time_min_sub, dT, 'r', 'LineWidth', 1.5);
ylabel('Delta T (Out - In) [°C]');
title(['Time Interval: ', num2str(t_start/60), ' - ', num2str(t_end/60), ' min']);
grid on;

subplot(2,1,2)
plot(time_min_sub, Flow_estimated, 'b', 'LineWidth', 1.5);
hold on;
yline(mean_flow_est, 'g--', ['Average: ', num2str(mean_flow_est, '%.3f'), ' L/min'], 'LineWidth', 2);
xlabel('Time [min]');
ylabel('Estimated Flow [L/min]');
title(['Assumed Power P = ', num2str(P_target), ' W']);
grid on;

fprintf('--- RESULTS --- \n');
fprintf('Average measured Delta T: %.2f °C\n', nanmean(dT));
fprintf('Calculated estimated flow: %.4f L/min\n', mean_flow_est);