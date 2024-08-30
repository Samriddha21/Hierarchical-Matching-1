function proposals_random = random_allocation(num_users, num_mvno)
    % Initialize proposals_random array to store random allocations
    proposals_random = zeros(num_users, 2);
    
    % Generate random allocations for each user
    for i = 1:num_users
        % Randomly select an MVNO index for the current user
        mvno_index = randi([1, num_mvno]);
        
        % Store the user index and the selected MVNO index in proposals_random
        proposals_random(i, :) = [i, mvno_index];
    end
end
