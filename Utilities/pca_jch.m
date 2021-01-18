function  [this_other_obs eig_vals ]=pca_jch(X,npc)

%first check
if nargin == 0
error('Too few inputs')
end

% %second check
% % for i = 1:size(X,2)
% %     fin = [];
% %     fin = find(isfinite(X(:,i)),1,'first');
% %     if fin ~= 1
% %     msg = 'PCA requires balances matrix';
% %     error(msg)
% %     end
% % end
    
    this_other_obs=X';
    mean_this_other_obs = mean(this_other_obs,2);
    this_other_obs_demeaned = this_other_obs-kron(mean_this_other_obs,ones(1,size(this_other_obs,2)));
    std_this_other_obs = sqrt(var(this_other_obs')');
    this_other_obs_demeaned_normalized = this_other_obs_demeaned./kron(std_this_other_obs,ones(1,size(this_other_obs,2)));
    [V,D] = eig(this_other_obs_demeaned_normalized*this_other_obs_demeaned_normalized');
    this_other_obs = this_other_obs_demeaned_normalized'*V(:,end-(npc-1):end);
    this_other_obs = this_other_obs(:,[ npc:-1:1 ]); %reordering the factors from largest to smallest
    eig_vals = diag(D);
    eig_vals = eig_vals/sum(eig_vals);
    eig_vals = eig_vals(end-npc+1:end);
    eig_vals = eig_vals(npc:-1:1);
end