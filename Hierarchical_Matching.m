clc;
clear all;

% Define environment parameters
num_mvno = 5;  % Number of MVNOs
num_inp = 5;   % Number of InPs
num_ue = 100;  % Number of UEs
coverage_area = [1000 1000]; % Coverage area as a row vector

% Channel and weight parameters
channel_bandwidth = 1.4e6; % Bandwidth in MHz
weight_parameter = 1;

% Demand and price ranges
ue_demand_range = [1 3]; % bps/Hz
mvno_price_range = [4 8]; % monetary units/bps/Hz
inp_price_range = [2 4]; % monetary units/bps/Hz

num_channels_inp = 20;

% Function to initialize environment
function [inp_locations, ue_locations, ue_demands, mvno_prices, inp_prices] = initialize_environment(num_mvno, num_inp, num_ue, coverage_area, ue_demand_range, mvno_price_range, inp_price_range)
  % Generate random locations
  inp_locations = rand(num_inp, 2) .* coverage_area;
  ue_locations = rand(num_ue, 2) .* coverage_area;
  
  % Generate random demands and prices
  ue_demands = rand(num_ue, 1) .* (ue_demand_range(2) - ue_demand_range(1)) + ue_demand_range(1);
  mvno_prices = rand(num_mvno, 1) .* (mvno_price_range(2) - mvno_price_range(1)) + mvno_price_range(1);
  inp_prices = rand(num_inp, 1) .* (inp_price_range(2) - inp_price_range(1)) + inp_price_range(1);
end

% Example usage
[inp_locations, ue_locations, ue_demands, mvno_prices, inp_prices] = initialize_environment(num_mvno, num_inp, num_ue, coverage_area, ue_demand_range, mvno_price_range, inp_price_range);

% Plot MVNO, InP, and UE locations
figure;
hold on;
scatter(inp_locations(:,1), inp_locations(:,2), 'rx', 'DisplayName', 'InP');
scatter(ue_locations(:,1), ue_locations(:,2), 'g+', 'DisplayName', 'UE');
xlabel('X Coordinate');
ylabel('Y Coordinate');
title('Locations of InPs, and UEs');
legend('Location', 'best');
grid on;
hold off;

% Creation of Prefrence lists
[sorted_demands, indices] = sort(mvno_prices);

% Create ue_preference_list with the indices of the sorted mvno_demands
ue_preference_list = indices;
ue_preference = generate_output(ue_preference_list)
ue_preference_profile = repmat(ue_preference, num_ue, 1);

distance_matrix = zeros(num_ue, num_inp);

% Calculate Euclidean distance between each pair of points
for i = 1:num_ue
    for j = 1:num_inp
        distance_matrix(i, j) = sqrt(sum((ue_locations(i,:) - inp_locations(j,:)).^2));
    end
end
sinr_matrix = sinr(distance_matrix)
channels_rqd = ceil(ue_demands ./ sinr_matrix)

mvno_preference_profile = zeros(num_mvno * num_inp, num_ue);

% Iterate over each MVNO and INP pairing
pair_index = 1;
for mvno = 1:num_mvno
    for inp = 1:num_inp
        % Compute the utility for each user
        utility = max(mvno_prices(mvno) * ue_demands - inp_prices(inp) * channels_rqd(:, inp), 0);
        
        % Sort users based on utility and get the indices
        [~, sorted_indices] = sort(utility, 'descend');
        
        % Store the sorted indices in the MVNO preference profile matrix
        mvno_preference_profile(pair_index, :) = sorted_indices;
        
        % Move to the next pairing
        pair_index = pair_index + 1;
    end
end

% Display the MVNO preference profile matrix
disp("MVNO Preference Profile Matrix:");
disp(mvno_preference_profile);

Q = num_channels_inp * ones(num_inp, 1);
Proposals = propose_users_1(ue_preference_profile, mvno_preference_profile, channels_rqd, Q)

%mvno_data_rates = zeros(25, 1); % Initialize array to store data rates for each MVNO
    
% Iterate through Proposals array
%for i = 1:size(Proposals, 1)
    %user_idx = Proposals(i, 1); % User index
    %mvno_idx = Proposals(i, 2); % MVNO index
        
    % Add user's data rate to the corresponding MVNO's total data rate
    %mvno_data_rates(mvno_idx) = mvno_data_rates(mvno_idx) + ue_demands(user_idx);
%end
%total_channel_price = inp_prices * (mvno_data_rates)'
proposals_random = random_allocation(num_ue, num_mvno)

sum = 0;
sum_rand = 0;
for i = 1:size(Proposals, 1)
    % Extract user index and MVNO index
    user_idx = Proposals(i, 1);
    mvno_idx = Proposals(i, 2);
        
    % Find the true MVNO index
    true_mvno_idx = ceil(mvno_idx / 5);
        
    % Find the user's data demand
    demand = ue_demands(user_idx);
        
    % Calculate total MVNO price paid
    temp = demand * mvno_prices(true_mvno_idx);
    sum = sum + temp;
end

for i = 1:size(proposals_random, 1)
    % Extract user index and MVNO index
    user_idx = proposals_random(i, 1);
    mvno_idx = proposals_random(i, 2);
           
    % Find the user's data demand
    demand = ue_demands(user_idx);
        
    % Calculate total MVNO price paid
    temp = demand * mvno_prices(mvno_idx);
    sum_rand = sum_rand + temp;
end

% Creation of Prefrence lists
[sorted_inp_prices, indices_inp] = sort(inp_prices);

% Create ue_preference_list with the indices of the sorted mvno_demands
mvno_preference_u = indices_inp;

% Initialize total channel requirements array for each InP
total_channel_requirements = zeros(num_inp * num_mvno, 1);

% Iterate through Proposals array
for i = 1:size(Proposals, 1)
    % Extract user index and MVNO index
    user_idx = Proposals(i, 1);
    mvno_idx = Proposals(i, 2);
    
    % Determine the corresponding InP based on the formula
    inp_idx = mod(mvno_idx, num_inp);
    if inp_idx == 0
        inp_idx = num_inp; % If the result is 0, set it to num_inp
    end
    
    % Add channels required to the total for the corresponding InP
    total_channel_requirements(mvno_idx) = total_channel_requirements(mvno_idx) + channels_rqd(user_idx, inp_idx);
end

% Reshape inp_prices to a column vector
inp_prices_col = inp_prices(:);

% Perform element-wise multiplication using broadcasting
total_cost_matrix = inp_prices_col * total_channel_requirements';

inp_sinr = zeros(5, 25);

% Iterate over MVNOs
for inp = 1:5
    for mvno = 1:25
        % Extract users assigned to current MVNO
        assigned_users = find(Proposals(:, 2) == mvno);
        
        % Initialize total SINR for the current MVNO
        total_sinr = 0;
        
        % Iterate through the list of assigned users and calculate the sum of SINR
        for user_idx = assigned_users'
            % Check if user index is within the bounds of sinr_matrix
            if user_idx <= size(sinr_matrix, 1) && user_idx > 0
                % Accumulate SINR for the current user and MVNO
                total_sinr = total_sinr + sinr_matrix(user_idx, inp);
            end
        end
        
        % Store total SINR in inp_sinr array
        inp_sinr(inp, mvno) = total_sinr;
    end
end

% Normalize inp_sinr
inp_sinr_normalized = inp_sinr ./ max(inp_sinr(:));
% Normalize total_cost_matrix
total_cost_matrix_normalized = total_cost_matrix ./ max(total_cost_matrix(:));

% Step 2: Add the normalized matrices element-wise
inp_combined_matrix = inp_sinr_normalized + total_cost_matrix_normalized;

inp_preference_profile = zeros(5, 25);

% Iterate over each InP
for inp = 1:5
    % Get the combined matrix values for the current InP
    combined_values = inp_combined_matrix(inp, :);
    
    % Sort the combined values in descending order and get the indices
    [~, sorted_indices] = sort(combined_values, 'descend');
    
    % Assign the sorted indices to the inp_preference_profile matrix
    inp_preference_profile(inp, :) = sorted_indices;
end

Q = num_channels_inp * ones(num_inp, 1);
Proposals_u = propose_users_u(mvno_preference_u, inp_preference_profile, total_channel_requirements, Q)

Proposals_lu = zeros(size(Proposals, 1), 3);  % Initialize array
    
% Iterate through each row of Proposals
for i = 1:size(Proposals, 1)
    user = Proposals(i, 1);   % User ID
    mvno = Proposals(i, 2);   % MVNO ID
        
    % Find corresponding input from Proposals_u
    idx = find(Proposals_u(:, 1) == mvno);
    inp = Proposals_u(idx, 2);
        
    % Store user, MVNO, and input in Proposals_lu
    Proposals_lu(i, :) = [user, mvno, inp];
end

total_sinr = 0;
for i = 1:size(Proposals_lu, 1)
    user = Proposals_lu(i, 1);
    inp = Proposals_lu(i, 3);  % Input ID
        
    % Find corresponding SINR value from sinr_matrix
    sinr = sinr_matrix(user, inp);
        
    % Add SINR to total_sinr
    total_sinr = total_sinr + sinr;
end

total_sinr_rand = 0;
for i = 1:size(Proposals_lu, 1)
    user = Proposals_lu(i, 1);
    inp = randi([1, 5]);

    sinr = sinr_matrix(user, inp);
    total_sinr_rand = total_sinr_rand + sinr;
end

max_mvno = 5;  % Calculate the maximum number of MVNOs

users_serviced = zeros(1, max_mvno);  % Initialize array to store the count of users serviced by each true MVNO
users_serviced_rand = zeros(1, max_mvno);

% Iterate through each row of Proposals
for i = 1:size(Proposals, 1)
    mvno = Proposals(i, 2);  % MVNO ID
    true_mvno = ceil(mvno / 5);  % Calculate true MVNO index
        
    % Increment the count of users serviced by the true MVNO
    users_serviced(true_mvno) = users_serviced(true_mvno) + 1;
end

for i = 1:size(Proposals, 1)
    mvno = randi([1, 5]);
    users_serviced_rand(mvno) = users_serviced_rand(mvno) + 1;
end

inp_no = zeros(1, 5);
inp_no_rand = zeros(1, 5);
for i = 1:size(Proposals_lu, 1)
    inp = Proposals_lu(i, 3);  % MVNO ID
        
    % Increment the count of users serviced by the true MVNO
    inp_no(inp) = inp_no(inp) + 1;
end

for i = 1:size(Proposals_lu, 1)
    inp = randi([1, 5]);
    inp_no_rand(inp) = inp_no_rand(inp) + 1;
end

total_revenue_inp = 0;
total_revenue_inp_rand = 0;

% Iterate through each row of Proposals_u
for i = 1:size(Proposals_u, 1)
    mvno = Proposals_u(i, 1);  % MVNO ID
    inp = Proposals_u(i, 2);   % Input ID
       
    % Calculate total channels required for the MVNO
    total_channels_required = total_channel_requirements(mvno);
        
    % Multiply total channels required by corresponding input price
    revenue = total_channels_required * inp_prices(inp);
        
    % Update total revenue for the input
    total_revenue_inp = total_revenue_inp + revenue;
end

% Iterate through each row of Proposals_u
for i = 1:size(Proposals_u, 1)
    mvno = Proposals_u(i, 1);  % MVNO ID
    inp = randi([1, 5])  % Input ID
       
    % Calculate total channels required for the MVNO
    total_channels_required = total_channel_requirements(mvno);
        
    % Multiply total channels required by corresponding input price
    revenue = total_channels_required * inp_prices(inp);
        
    % Update total revenue for the input
    total_revenue_inp_rand = total_revenue_inp_rand + revenue;
end