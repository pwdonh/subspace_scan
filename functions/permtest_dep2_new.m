function [pval, stat_obs, stat_perm] = permtest_dep2_new(inputsA, inputsB, para)

% parse inputs
nInst = numel(inputsA); % number of instances
if nInst~=numel(inputsB)
    bst_error('Need same number of inputs A & B');
end
obs_sample = {inputsA, inputsB};

%% observed statistic

stat_obs = feval(para.func, obs_sample, para);

%% determine permutation sample space

nPermAll = 2^nInst; % all possible permutations
if nPermAll>para.nPerm
    % Select monte-carlo samples from the space of possible
    % permutations (without replacement)
    nPerm = para.nPerm;
    isStop = 0;
    indSamples = zeros(0,nInst);
    while ~isStop
        for iPerm = 1:nPerm-size(indSamples,1)
            indSamplesNew(iPerm,:) = randsample(0:1, nInst, 1);
        end
        indSamples = [indSamples; indSamplesNew];
        indSamples = unique(indSamples,'rows');
        if size(indSamples,1)==nPerm
            isStop = 1;
        end
        clear indSamplesNew
    end
else
    % Perform exhaustive permutations
    indSamples = permn(1:2, numel(inputsA))-1;
    nPerm = size(indSamples,1);
end

%% calculate permutation distribution

if para.verbose
    fprintf('Permutation     0 of %5d\n', nPerm);
end
if ~para.isMaximum
    stat_perm = zeros(size(stat_obs,1), nPerm);
else
    maxstat = zeros(1, nPerm);
    minstat = zeros(1, nPerm);
end
for iPerm = 1:nPerm
    perm_sample = {};
    if para.verbose
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%5d of %5d\n', iPerm, nPerm);
    end
    % build permutation sample
    indSample = indSamples(iPerm, :);
    for iInst = 1:nInst
        perm_sample{1}{iInst} = obs_sample{indSample(iInst)+1}{iInst};
        perm_sample{2}{iInst} = obs_sample{~indSample(iInst)+1}{iInst};
    end
    % compute statistic
    stat_perm_tmp = feval(para.func, perm_sample, para);
    if ~para.isMaximum
        stat_perm(:,iPerm) = stat_perm_tmp;
    else
        maxstat(iPerm) = max(stat_perm_tmp);
        minstat(iPerm) = min(stat_perm_tmp);
    end
end

%% compute p-values

% compute p-value as the ratio of permutation samples higher than the
% observed one (times 2 for two-tailed test)
isPos = stat_obs'>=para.stat0;
if ~para.isMaximum % treat every dimension separately
    n = sum(bsxfun(@gt, stat_obs', stat_perm'));
%     pval = ((n+1)./(nPerm+1));
    pval = ones(1,size(stat_obs,1));
    pval(~isPos) = ((n(~isPos)+1)./(nPerm+1));
    pval(isPos) = ((nPerm-n(isPos)+1)./(nPerm+1));
else % use maximum statistic
%     pval = ones(1,size(stat_obs,1));
%     maxstat = max(stat_perm);
%     n = sum(bsxfun(@gt, stat_obs', repmat(maxstat,size(stat_obs,1),1)'));
%     pval(isPos) = ((nPerm-n(isPos)+1)./(nPerm+1));
%     minstat = min(stat_perm);
%     n = sum(bsxfun(@lt, stat_obs', repmat(minstat,size(stat_obs,1),1)'));
%     pval(~isPos) = ((nPerm-n(~isPos)+1)./(nPerm+1));
    pval_pos = ones(1,size(stat_obs,1));
    pval_neg = ones(1,size(stat_obs,1));
    for iSource = 1:size(stat_obs,1)
        n = sum(stat_obs(iSource)>maxstat);
        pval_pos(iSource) = ((nPerm-n+1)./(nPerm+1));
        n = sum(stat_obs(iSource)<minstat);
        pval_neg(iSource) = ((nPerm-n+1)./(nPerm+1));                
    end
    pval = pval_pos;
    pval(~isPos) = pval_neg(~isPos);
end
pval = pval*2;
pval(pval>1) = 1;

if para.isMaximum
    stat_perm = maxstat;
end

end




