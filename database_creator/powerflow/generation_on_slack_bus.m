function delta_Pg_slack_neg = generation_on_slack_bus(results, cfg)
% GENERATION_ON_SLACK_BUS  Compute the slack-bus generation violation (below Pmin or above Pmax) to redispatch.

    define_constants;

    slack_bus = results.bus(results.bus(:,PG)==3,GEN_BUS);
    idx_slack   = find(results.gen(:,GEN_BUS)==slack_bus);
    Pg   = results.gen(idx_slack,PG);
    Pmax_slack = results.gen(idx_slack,PMAX);
    Pmin_slack = results.gen(idx_slack,PMIN);
    
    if Pmin_slack <= 0
        Pmin_slack = cfg.powerflow.validation.minPowerSlack*Pmax_slack;
    end
    
    delta_Pg_slack_neg = max([0; -Pg+Pmin_slack]);
    % delta_Pg_slack_pos = max([0; Pg-Pmax_slack]);

end