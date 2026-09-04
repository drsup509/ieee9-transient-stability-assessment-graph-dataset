function mpc = redispatch_delta_mw_slack(mpc, delta_Pg_slack_neg)
% REDISPATCH_DELTA_MW_SLACK  Shift a slack-bus generation excess/deficit onto the other generators.

    fprintf('\n========================================\n');
    fprintf('REDISPATCH \n');
    fprintf('========================================\n');

    define_constants;    


    fprintf('\n========================================\n');
    fprintf('Slack bus négatif ou plus grand que Pmax \n');

    % slack_bus = results.bus(results.bus(:,PG)==3,GEN_BUS);
    % idx_slack   = find(results.gen(:,GEN_BUS)==slack_bus);
    % Pg   = results.gen(idx_slack,PG);
    % Pmax_slack = results.gen(idx_slack,PMAX);
    % Pmin_slack = results.gen(idx_slack,PMIN);
    % 
    % if Pmin_slack <= 0
    %     Pmin_slack = cfg.powerflow.validation.minPowerSlack*Pmax_slack;
    % end
    % 
    % delta_Pg_slack_neg = max([0; -Pg+Pmin_slack])
    % delta_Pg_slack_pos = max([0; Pg-Pmax_slack]);
    

    slack_bus = find(mpc.bus(:, BUS_TYPE) == REF);
    idx_slack = find(mpc.gen(:, GEN_BUS) == slack_bus);
    
    
    % Autres générateurs
    idx_non_slack = setdiff(1:size(mpc.gen,1), idx_gen);
    
    % Production actuelle
    Pg_other = mpc.gen(idx_non_slack,PG);
    
    
    % 
    %  % Pondération proportionnelle
    % w = Pg_other / sum(Pg_other);
    
    % % Réduction proportionnelle
    % mpc.gen(idx_non_slack,PG) = Pg_other - delta_Pg_slack_neg*w;
    
    
    % Production selon marge haute et basse
    Pg_other_margin_high = mpc.gen(idx_non_slack,PMAX) - ...
        mpc.gen(idx_non_slack,PG);
    Pg_other_margin_low = mpc.gen(idx_non_slack,PG) - ...
        mpc.gen(idx_non_slack,PMIN);
    
    sum(Pg_other_margin_high)
    
    
    % Pondération par marge
    w = Pg_other_margin_low / sum(Pg_other_margin_low);
    
    % Réduction par marge
    mpc.gen(idx_non_slack,PG) = Pg_other - delta_Pg_slack_neg*w;
    
    
    % Fixer le slack à delta
    mpc.gen(idx_slack,PG) = delta_Pg_slack_neg ;

    fprintf('\n========================================\n');
    fprintf(' FIN REDISPATCH \n');
    fprintf('========================================\n');

end