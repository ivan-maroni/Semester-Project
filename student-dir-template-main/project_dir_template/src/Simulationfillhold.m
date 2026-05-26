%% Pasteurization Fill & Hold Simulation - Energy Analysis
clear; clc;

% --- INPUT PARAMETERS ---
m_tube = 0.035;             
m_tank = 1.2;               
P_solar = 125.0;           
T_setpoint = 73;           
T_start_tank = 30;         
T_reset_tube = 30;         
cp = 4186;                 

t_flow = 9;                
t_sim_min = 90;            
t_time = 0:1:(t_sim_min * 60);

% --- STATE VARIABLES ---
T_tank = zeros(size(t_time));
T_tube = zeros(size(t_time));
T_tank_current = T_start_tank;
T_tube_current = T_start_tank;
is_pumping = false;

% --- SIMULATION ---
for t = 1:length(t_time)
    
    if T_tube_current < T_setpoint && ~is_pumping
        % TUBE HEATING
        dT_tube = P_solar / (m_tube * cp);
        T_tube_current = T_tube_current + dT_tube;
        
    elseif T_tube_current >= T_setpoint && ~is_pumping
        % PUMP ACTIVATION
        is_pumping = true;
        pump_start_time = t;
    end
    
    if is_pumping
        if (t - pump_start_time) < t_flow
            % HEAT TRANSFER TO TANK
            mass_flow_rate = m_tube / t_flow;
            dT_tank = (mass_flow_rate * (T_tube_current - T_tank_current)) / m_tank;
            T_tank_current = T_tank_current + dT_tank;
        else
            % TUBE RESET TO COLD TEMPERATURE
            is_pumping = false;
            T_tube_current = T_reset_tube;
        end
    end
    
    T_tank(t) = T_tank_current;
    T_tube(t) = T_tube_current;
end

% --- PLOTTING ---
figure('Color', 'w');

% 🔴 Tank
subplot(2,1,1);
plot(t_time/60, T_tank, 'r', 'LineWidth', 2); hold on;
yline(70, '--k', 'Pasteurization Target');
grid on;
ylabel('Tank Temperature (°C)');
title('Tank Temperature Evolution');

% 🔵 Tube
subplot(2,1,2);
plot(t_time/60, T_tube, 'b', 'LineWidth', 1.5);
grid on;
ylabel('Tube Temperature (°C)');
xlabel('Time (minutes)');
title('Tube Thermal Cycles (Fill & Hold)');

% --- OUTPUT ---
idx = find(T_tank >= 70, 1);
if ~isempty(idx)
    fprintf('Time to reach 70°C: %.1f minutes\n', idx / 60);
else
    fprintf('70°C not reached within simulation time.\n');
end