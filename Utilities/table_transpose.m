function mytable_transpose = table_transpose(mytable)

% transpose dataset so that the observations for each bank appear as
% columns

id_list = unique(mytable{:,'ID_RSSD'});

nids = size(id_list,1);


for indx = 1:nids
    this_bank_id = id_list(indx);
    
    this_bank_table = mytable(mytable{:,'ID_RSSD'} == this_bank_id,:);
    this_bank_short_name = this_bank_table{1,{'bank_short_name'}};
    
    this_bank_table.Properties.VariableNames(end)= cellstr(this_bank_short_name);
    if indx ==1
        mytable_transpose = this_bank_table(:,{'date',char(this_bank_short_name)});
    else 
        mytable_transpose = join(mytable_transpose,this_bank_table(:,{'date',char(this_bank_short_name)}),'LeftKeys','date','RightKeys','date');
    end
end