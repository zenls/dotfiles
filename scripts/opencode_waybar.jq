# API schema verified against OpenCode 2.2.7 on this system.
def waiting: (.permissions|length) + (.forms|length) > 0;
def rank: if waiting then 2 elif .working then 1 else 0 end;
def root_id($index):
    if .parentID and $index[.parentID] then $index[.parentID] | root_id($index)
    else .parentID // .id end;

($directory | rtrimstr("/") | split("/") | last | if . == "" then "/" else . end) as $project |
if ($records|length) == 0 then
    if $error == "" then [] else
        [{id:("error:" + $directory + ":" + $client.session + ":" + $client.server),
          project:$project,title:"",state:"unavailable",permissions:0,forms:0,error:$error}]
    end
else
    ($records | map({key:.info.id,value:.info}) | from_entries) as $index |
    $records | group_by(.info | root_id($index)) | map(
        . as $group |
        ($group[0].info | root_id($index)) as $id |
        ($group | sort_by(rank) | last) as $attention |
        ([$group[] | select(.info.id == $id)][0] // $attention) as $root |
        ([$group[].permissions[]] | length) as $permissions |
        ([$group[].forms[]] | length) as $forms |
        {id:$id,project:$project,title:($root.info.title // $root.info.id),
         state:(if ($permissions + $forms) > 0 then "waiting"
                elif $error != "" then "unavailable"
                elif any($group[]; .working) then "working" else "idle" end),
         permissions:$permissions,forms:$forms,error:$error}
    )
end
