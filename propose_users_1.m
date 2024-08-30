function Proposals = propose_users_1(ue_preference_profile, mvno_preference_profile, channels_rqd, Q)
    % Initialize empty proposals array
    Proposals = [];
    
    binary_array = true(1, size(ue_preference_profile, 1));
    
    % Initialize an array to keep track of users allocated to each true MVNO
    true_mvno_counts = zeros(1, ceil(size(mvno_preference_profile, 1) / 5));
    max_iterations = 1000;

    % Stage 1: Low-Level Matching - Service Selection
    for iter = 1:max_iterations
        for i = 1:size(ue_preference_profile, 1)
            if binary_array(i) == false
                continue; % Skip the current iteration
            end

            for j = 1:size(ue_preference_profile, 2)
                if ue_preference_profile(i, j) ~= -1
                   n = ue_preference_profile(i, j);
                   break; % Exit loop once a non-negative value is found
                end
            end

            % Determine the channel requirement for user i
            k = mod(n, 5);
            if k == 0
                k = 5;
            end
            l = channels_rqd(i, k);

            % Get the true MVNO index for the current user
            true_mvno = ceil(n / 5);

            % Check if the true MVNO can serve more users
            if Q(k) >= l && true_mvno_counts(true_mvno) < 30
                % Decrement available channels
                Q(k) = Q(k) - l;
                % Add proposal to Proposals array
                Proposals = [Proposals; [i, n]];
                % Increment count for the true MVNO
                true_mvno_counts(true_mvno) = true_mvno_counts(true_mvno) + 1;
                binary_array(i) = false;
            else
                % Find the index of user i in the MVNO preference profile
                x = find(mvno_preference_profile(n, :) == i);
                % Check proposals array for users paired with this specific MVNO where the paired user index is greater than x
                for idx = size(Proposals, 1):-1:1
                    if Proposals(idx, 2) == n && any(find(mvno_preference_profile(n, :) == Proposals(idx, 1)) > x)
                        % Remove the less preferred user from Proposals
                        removed_user = Proposals(idx, 1);
                        Proposals(idx, :) = [];
                        % Mark the binary_array for the removed user as true
                        binary_array(removed_user) = true;
                        % Add back the channels required by the removed user to Q
                        k_removed = mod(n, 5);
                        if k_removed == 0
                            k_removed = 5;
                        end
                        Q(k_removed) = Q(k_removed) + channels_rqd(removed_user, k_removed);
                        % Decrement count for the true MVNO
                        true_mvno_counts(true_mvno) = true_mvno_counts(true_mvno) - 1;
                    end
                end

                % Check if Q(k) can be made greater than l after removing less preferred users
                if Q(k) >= l && true_mvno_counts(true_mvno) < 30
                    % Decrement available channels
                    Q(k) = Q(k) - l;
                    % Add proposal to Proposals array
                    Proposals = [Proposals; [i, n]];
                    % Increment count for the true MVNO
                    true_mvno_counts(true_mvno) = true_mvno_counts(true_mvno) + 1;
                    binary_array(i) = false;
                else
                    % Remove the MVNO from the user preference list of user i
                    ue_preference_profile(i, j) = -1;
                end
            end
        end
    end
end
