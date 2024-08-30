function output = generate_output(ue_preference_list)
    output = [];
    for i = 1:length(ue_preference_list)
        num = ue_preference_list(i);
        lower_bound = ((num - 1) * 5)+1;
        upper_bound = num * 5;
        range = lower_bound:upper_bound;
        output = [output, range(randperm(length(range), 5))];
    end
end